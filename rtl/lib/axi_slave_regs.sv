// `default_nettype none
`timescale 1ns / 1ps

// AXI4 write-only slave — simulation / verification use only.
//
// Features
//   • Random independent backpressure on AWREADY, WREADY, and BVALID so that
//     every combination of stall-vs-progress is exercised across a run.
//   • In-order single-outstanding operation (no write-data interleaving queues).
//   • Associative-array memory model — every accepted beat is stored and
//     readable from the testbench via hierarchical reference.
//   • Hard $fatal on every AXI4 protocol violation; covers both the master's
//     obligations (valid-stability, signal-stability, alignment) and the
//     slave's self-consistency (BVALID stability, BID correctness).
//
// Limitations (deliberate, not bugs)
//   • AR/R channels not present.
//   • W-before-AW: AXI4-legal but li_save never does it; WVALID in IDLE
//     logs a warning and stalls until AW arrives, which is correct behavior.
//   • No interleaved multi-ID writes (single-outstanding enforced as an
//     assertion because li_save guarantees it).
//
// Parameters
//   DATA_WIDTH  — AXI data bus width in bits (must be 128 for li_save)
//   ADDR_WIDTH  — AXI address width in bits
//   ID_WIDTH    — AXI ID width in bits

module axi_slave_regs
   #(parameter int DATA_WIDTH = 128,
     parameter int ADDR_WIDTH = 49,
     parameter int ID_WIDTH   = 6)
    (input  logic i_clk,
     input  logic i_rst,

     // AW channel (master → slave)
     input  logic                    i_awvalid,
     output logic                    o_awready,
     input  logic [ID_WIDTH-1:0]     i_awid,
     input  logic [ADDR_WIDTH-1:0]   i_awaddr,
     input  logic [1:0]              i_awburst,
     input  logic [2:0]              i_awsize,
     input  logic [7:0]              i_awlen,
     input  logic [3:0]              i_awcache,
     input  logic [2:0]              i_awprot,
     input  logic [3:0]              i_awqos,
     input  logic                    i_awlock,
     input  logic                    i_awuser,

     // W channel (master → slave)
     input  logic                        i_wvalid,
     output logic                        o_wready,
     input  logic [DATA_WIDTH-1:0]       i_wdata,
     input  logic [DATA_WIDTH/8-1:0]     i_wstrb,
     input  logic                        i_wlast,

     // B channel (slave → master)
     output logic                    o_bvalid,
     input  logic                    i_bready,
     output logic [ID_WIDTH-1:0]     o_bid,
     output logic [1:0]              o_bresp);

    localparam int BEAT_BYTES = DATA_WIDTH / 8;  // 16 for 128-bit bus

    // =========================================================================
    // Memory model
    // =========================================================================
    // Key: byte address of the 128-bit beat (always BEAT_BYTES-aligned).
    // Readable from outside via hierarchical reference, e.g.
    //   DUT.SLAVE.mem[64'h800000000]
    logic [DATA_WIDTH-1:0] mem [longint unsigned];

    // =========================================================================
    // State machine
    // =========================================================================
    typedef enum logic [1:0] {IDLE, WDATA, BRESP} state_t;
    state_t r_state;

    // Transaction context, latched at AW handshake
    logic [ID_WIDTH-1:0]   r_awid;
    logic [ADDR_WIDTH-1:0] r_awaddr;
    logic [7:0]            r_awlen;   // number of beats - 1
    logic [7:0]            r_beat;    // current beat index (0-indexed)

    // =========================================================================
    // Random backpressure — re-sampled every clock so stall patterns vary
    // =========================================================================
    logic r_aw_rnd;   // 1 → awready may assert this cycle
    logic r_w_rnd;    // 1 → wready  may assert this cycle
    logic r_b_rnd;    // 1 → bvalid  attempts to assert this cycle (25 % rate)

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_aw_rnd <= 1'b0;
            r_w_rnd  <= 1'b0;
            r_b_rnd  <= 1'b0;
        end else begin
            r_aw_rnd <= $urandom_range(0, 1);
            r_w_rnd  <= $urandom_range(0, 1);
            r_b_rnd  <= ($urandom_range(0, 3) == 0);
        end
    end

    // =========================================================================
    // Channel outputs
    // =========================================================================
    assign o_awready = (r_state == IDLE)  && r_aw_rnd;
    assign o_wready  = (r_state == WDATA) && r_w_rnd;
    assign o_bresp   = 2'b00;  // always OKAY

    // B valid/id are registered so they can be held stable once asserted
    logic              r_bvalid;
    logic [ID_WIDTH-1:0] r_bid;
    assign o_bvalid = r_bvalid;
    assign o_bid    = r_bid;

    // =========================================================================
    // Beat address (combinatorial, used in WDATA state)
    // =========================================================================
    logic [63:0] w_beat_addr;
    assign w_beat_addr = 64'(r_awaddr) + {56'h0, r_beat, 4'h0};

    // =========================================================================
    // Main FSM
    // =========================================================================
    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            r_state  <= IDLE;
            r_awid   <= '0;
            r_awaddr <= '0;
            r_awlen  <= '0;
            r_beat   <= '0;
            r_bvalid <= 1'b0;
            r_bid    <= '0;

        end else begin

            case (r_state)

                // -----------------------------------------------------------------
                IDLE: begin
                    if (i_awvalid && o_awready) begin
                        r_awid   <= i_awid;
                        r_awaddr <= i_awaddr;
                        r_awlen  <= i_awlen;
                        r_beat   <= '0;
                        r_state  <= WDATA;

                        // --- immediate checks at AW handshake ---

                        AXICHK_AW_BURST: assert (i_awburst == 2'b01)
                            else $fatal(1, "[axi_slave] @%0t AWBURST=0b%02b, expected INCR (0b01)",
                                        $time, i_awburst);

                        AXICHK_AW_SIZE: assert (i_awsize == 3'b100)
                            else $fatal(1, "[axi_slave] @%0t AWSIZE=0b%03b, expected 0b100 (16 B)",
                                        $time, i_awsize);

                        AXICHK_AW_ALIGN: assert (i_awaddr[3:0] == 4'h0)
                            else $fatal(1, "[axi_slave] @%0t AWADDR=0x%012h not 16-byte aligned",
                                        $time, i_awaddr);

                        // 4 KB boundary: awaddr[11:0] + (awlen+1)*16 <= 4096
                        // All operands widen to 13 bits; max sum = 4095+4096 = 8191 < 2^13
                        AXICHK_AW_4KB: assert (
                            {1'b0, i_awaddr[11:0]} + {1'b0, i_awlen, 4'h0} + 13'd16 <= 13'h1000
                        ) else $fatal(1,
                            "[axi_slave] @%0t burst crosses 4 KB boundary: addr=0x%012h awlen=%0d",
                            $time, i_awaddr, i_awlen);

                        $display("[axi_slave] @%0t AW  id=%0d addr=0x%012h len=%0d beats=%0d",
                                 $time, i_awid, i_awaddr, i_awlen, i_awlen + 1);
                    end

                    // AXI4 allows W before AW; stall master with wready=0 until AW arrives.
                    // Log so it is visible during debug since li_save should never do this.
                    if (i_wvalid)
                        $display("[axi_slave] @%0t NOTE: WVALID asserted in IDLE (W before AW)", $time);
                end

                // -----------------------------------------------------------------
                WDATA: begin
                    if (i_wvalid && o_wready) begin

                        // check wlast against beat counter
                        if (r_beat < r_awlen) begin
                            AXICHK_NO_EARLY_WLAST: assert (!i_wlast)
                                else $fatal(1,
                                    "[axi_slave] @%0t WLAST asserted early: beat=%0d awlen=%0d",
                                    $time, r_beat, r_awlen);
                            r_beat <= r_beat + 8'd1;
                        end else begin
                            AXICHK_WLAST_ON_LAST: assert (i_wlast)
                                else $fatal(1,
                                    "[axi_slave] @%0t WLAST not asserted on final beat: beat=%0d awlen=%0d",
                                    $time, r_beat, r_awlen);
                            // last beat received — move to B
                            r_beat   <= '0;
                            r_bvalid <= r_b_rnd;  // may assert bvalid immediately
                            r_bid    <= r_awid;
                            r_state  <= BRESP;
                        end

                        // store beat in memory model
                        mem[w_beat_addr] <= i_wdata;
                    end
                end

                // -----------------------------------------------------------------
                BRESP: begin
                    // try to assert bvalid each cycle until it sticks
                    if (!r_bvalid)
                        r_bvalid <= r_b_rnd;

                    if (r_bvalid && i_bready) begin
                        r_bvalid <= 1'b0;
                        r_bid    <= '0;
                        r_state  <= IDLE;
                        $display("[axi_slave] @%0t B   id=%0d  (txn complete, addr=0x%012h len=%0d)",
                                 $time, r_awid, r_awaddr, r_awlen);
                    end
                end

            endcase
        end
    end

    // =========================================================================
    // AXI4 protocol compliance assertions
    // =========================================================================
    // All use posedge clk with synchronous reset disable.
    // Naming: <channel>_<what is checked>.

    // -------------------------------------------------------------------------
    // AW channel — master obligations
    // -------------------------------------------------------------------------

    // AWVALID must not drop until the handshake completes.
    AW_VALID_STABLE: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (i_awvalid && !o_awready) |=> i_awvalid
    ) else $fatal(1, "[axi_slave] @%0t AXI4: AWVALID deasserted before AWREADY", $time);

    // Every AW signal must be stable while awvalid is high without a handshake.
    AW_ID_STABLE: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (i_awvalid && !o_awready) |=> $stable(i_awid)
    ) else $fatal(1, "[axi_slave] @%0t AXI4: AWID changed while AWVALID without AWREADY", $time);

    AW_ADDR_STABLE: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (i_awvalid && !o_awready) |=> $stable(i_awaddr)
    ) else $fatal(1, "[axi_slave] @%0t AXI4: AWADDR changed while AWVALID without AWREADY", $time);

    AW_LEN_STABLE: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (i_awvalid && !o_awready) |=> $stable(i_awlen)
    ) else $fatal(1, "[axi_slave] @%0t AXI4: AWLEN changed while AWVALID without AWREADY", $time);

    AW_BURST_STABLE: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (i_awvalid && !o_awready) |=> $stable(i_awburst)
    ) else $fatal(1, "[axi_slave] @%0t AXI4: AWBURST changed while AWVALID without AWREADY", $time);

    AW_SIZE_STABLE: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (i_awvalid && !o_awready) |=> $stable(i_awsize)
    ) else $fatal(1, "[axi_slave] @%0t AXI4: AWSIZE changed while AWVALID without AWREADY", $time);

    AW_CACHE_STABLE: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (i_awvalid && !o_awready) |=> $stable(i_awcache)
    ) else $fatal(1, "[axi_slave] @%0t AXI4: AWCACHE changed while AWVALID without AWREADY", $time);

    AW_PROT_STABLE: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (i_awvalid && !o_awready) |=> $stable(i_awprot)
    ) else $fatal(1, "[axi_slave] @%0t AXI4: AWPROT changed while AWVALID without AWREADY", $time);

    AW_QOS_STABLE: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (i_awvalid && !o_awready) |=> $stable(i_awqos)
    ) else $fatal(1, "[axi_slave] @%0t AXI4: AWQOS changed while AWVALID without AWREADY", $time);

    AW_LOCK_STABLE: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (i_awvalid && !o_awready) |=> $stable(i_awlock)
    ) else $fatal(1, "[axi_slave] @%0t AXI4: AWLOCK changed while AWVALID without AWREADY", $time);

    // -------------------------------------------------------------------------
    // W channel — master obligations
    // -------------------------------------------------------------------------

    // WVALID must not drop until the handshake completes.
    W_VALID_STABLE: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (i_wvalid && !o_wready) |=> i_wvalid
    ) else $fatal(1, "[axi_slave] @%0t AXI4: WVALID deasserted before WREADY", $time);

    // All W payload signals must be stable while wvalid is high without a handshake.
    W_DATA_STABLE: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (i_wvalid && !o_wready) |=> $stable(i_wdata)
    ) else $fatal(1, "[axi_slave] @%0t AXI4: WDATA changed while WVALID without WREADY", $time);

    W_STRB_STABLE: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (i_wvalid && !o_wready) |=> $stable(i_wstrb)
    ) else $fatal(1, "[axi_slave] @%0t AXI4: WSTRB changed while WVALID without WREADY", $time);

    W_LAST_STABLE: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (i_wvalid && !o_wready) |=> $stable(i_wlast)
    ) else $fatal(1, "[axi_slave] @%0t AXI4: WLAST changed while WVALID without WREADY", $time);

    // -------------------------------------------------------------------------
    // B channel — slave self-consistency (we own these signals)
    // -------------------------------------------------------------------------

    // BVALID must not drop until bready acknowledges it.
    B_VALID_STABLE: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (o_bvalid && !i_bready) |=> o_bvalid
    ) else $fatal(1, "[axi_slave] @%0t internal: BVALID deasserted before BREADY", $time);

    // BID and BRESP must not change while bvalid is high.
    B_ID_STABLE: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (o_bvalid && !i_bready) |=> $stable(o_bid)
    ) else $fatal(1, "[axi_slave] @%0t internal: BID changed while BVALID without BREADY", $time);

    B_RESP_STABLE: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (o_bvalid && !i_bready) |=> $stable(o_bresp)
    ) else $fatal(1, "[axi_slave] @%0t internal: BRESP changed while BVALID without BREADY", $time);

    // BID echoed back must match the AWID of the current transaction.
    B_ID_MATCHES_AW: assert property (
        @(posedge i_clk) disable iff (i_rst)
        o_bvalid |-> (o_bid == r_awid)
    ) else $fatal(1, "[axi_slave] @%0t internal: BID=0x%0h != AWID=0x%0h",
                  $time, o_bid, r_awid);

    // BVALID must not be asserted outside of BRESP state.
    B_NO_SPURIOUS_BVALID: assert property (
        @(posedge i_clk) disable iff (i_rst)
        o_bvalid |-> (r_state == BRESP)
    ) else $fatal(1, "[axi_slave] @%0t internal: BVALID asserted outside BRESP state", $time);

    // -------------------------------------------------------------------------
    // Ordering constraints (li_save-specific: single-outstanding)
    // -------------------------------------------------------------------------

    // Once a transaction is in flight, li_save must not present a new AWVALID
    // until B is acknowledged and we return to IDLE.
    NO_NEW_AW_INFLIGHT: assert property (
        @(posedge i_clk) disable iff (i_rst)
        (r_state != IDLE) |-> !i_awvalid
    ) else $fatal(1,
        "[axi_slave] @%0t single-outstanding violated: AWVALID during active transaction (state=%s)",
        $time, r_state.name());

endmodule
