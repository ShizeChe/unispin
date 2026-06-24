`default_nettype none
`timescale 1ns / 1ps

module ad5791
   #(parameter real VMIN=-10.0,
     parameter real VMAX=10.0)
    (input  logic SCLK,
     input  logic SDIN,
     input  logic SYNC_N,
     output logic SDO,
     input  logic LDAC_N,
     input  logic CLR_N,
     input  logic RESET_N,

     output logic [19:0] VDIGITAL,
     output real VOUT);

    // mimic ad5791
    logic [19:0] dac_reg;
    logic [19:0] ctrl_reg;
    logic [19:0] clrcode_reg;
    logic [19:0] sw_ctrl_reg;

    logic [23:0] input_shift_reg;
    logic [19:0] dac_input_reg;

    logic rw;
    logic [2:0] addr;
    logic [19:0] data;

    assign {rw, addr, data} = input_shift_reg;

    task reset;
        dac_reg = 'h0;
        dac_input_reg = 'h0;

        ctrl_reg[19:10] = 10'h0; // Reserved
        ctrl_reg[9:6] = 4'h0; // LIN COMP
        ctrl_reg[5] = 1'b0; // SDODIS
        ctrl_reg[4] = 1'b0; // BIN/2sC
        ctrl_reg[3] = 1'b1; // DACTRI
        ctrl_reg[2] = 1'b1; // OPGND
        ctrl_reg[1] = 1'b1; // RBUF
        ctrl_reg[0] = 1'b0; // Reserved

        clrcode_reg = 'h0;

        sw_ctrl_reg[19:3] = 17'h0; // Reserved
        sw_ctrl_reg[2] = 1'b0; // RESET
        sw_ctrl_reg[1] = 1'b0; // CLR
        sw_ctrl_reg[0] = 1'b0; // LDAC
    endtask

    logic SDODIS, DACTRI, OPGND;
    assign SDODIS = ctrl_reg[5];
    assign DACTRI = ctrl_reg[3];
    assign OPGND = ctrl_reg[2];

    always @(posedge SYNC_N) begin
        if (!LDAC_N)
            dac_reg <= !CLR_N ? clrcode_reg : dac_input_reg;
    end

    always @(negedge LDAC_N) begin
        dac_reg <= !CLR_N ? clrcode_reg : dac_input_reg;
    end

    always @(negedge CLR_N) begin
        dac_reg <= clrcode_reg;
    end


    logic [23:0] rd_data;

    logic valid_transaction;

    initial begin

        reset;
        rd_data = 'h0;

        forever begin
             
            fork

                begin: RESET
                    wait(!RESET_N);
                    reset;
                end

                begin: SPI

                    @(negedge SYNC_N);

                    valid_transaction = 1'b0;

                    for (int i = 23; i >= 0; i--) begin

                        @(negedge SCLK);

                        if (!SYNC_N) begin
                            input_shift_reg[i] = SDIN;
                            SDO = SDODIS ? rd_data[i] : 1'b0;
                        end
                        else begin
                            input_shift_reg = 'h0;
                            SDO = 1'b0;
                            break;
                        end

                    end

                    // wait for posedge SYNC_N but abort transaction
                    // if more SCLK posedge comes
                    fork

                        begin: WAIT_SYNC_N
                            @(posedge SYNC_N);
                            valid_transaction = 1'b1;
                        end

                        begin: SCLK_CHANGES
                            @(posedge SCLK);
                        end

                    join_any
                    disable fork;

                    if (valid_transaction) begin

                        if (rw == 1'b0) begin
                            if (addr == 3'b001)
                                dac_input_reg = data;
                            else if (addr == 3'b010)
                                ctrl_reg = data;
                            else if (addr == 3'b011)
                                clrcode_reg = data;
                            else if (addr == 3'b100) begin
                                sw_ctrl_reg = data;
                                if (data[0])
                                    dac_reg = dac_input_reg;
                                if (data[1])
                                    dac_reg = clrcode_reg;
                                if (data[2])
                                    reset;
                            end
                        end
                        else begin
                            if (addr == 3'b001)
                                rd_data = dac_reg;
                            else if (addr == 3'b010)
                                rd_data = ctrl_reg;
                            else if (addr == 3'b011)
                                rd_data = clrcode_reg;
                            else if (addr == 3'b100)
                                rd_data = sw_ctrl_reg;
                        end

                    end
                    else begin
                        input_shift_reg = 'h0;
                        SDO = 1'b0;
                    end

                end

            join_any
            disable fork;

        end
    end

    assign VDIGITAL = (OPGND || DACTRI) ? 'h0 : dac_reg;

    function automatic real vdigital2real(input logic [19:0] vdigital);
        return (VMAX - VMIN) / (1.0 * (2 ** 20 - 1)) * $itor($signed(vdigital));
    endfunction

    assign VOUT = vdigital2real(VDIGITAL);

endmodule

