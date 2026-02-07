/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"

static u32 launch_regs[] = {
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000

};

static u32 dc_base_addr = 0xA0005000;
static u32 launch_base_addr = 0xA001E000;

static u32 dc_regs[] = {
    0x00000800,
    0x00800000,
    0x00000000,
    0x00024766,
    0x66422221,
    0x02FAF080,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000001,
    0x00000001,
    0x0000FFFF,
    0x0000FFFF,
    0x0000FFFF,
    0x00000001
};

int dc_test(void) {

    s32 Status = XST_SUCCESS;

    sint32 i;

    Xil_Out32(dc_base_addr + 4 * 35, 0);
    for (i = 32; i < 35; i++) {
        Xil_Out32(dc_base_addr + 4 * i, dc_regs[i]);
    }
    Xil_Out32(dc_base_addr + 4 * 35, dc_regs[35]);

    Xil_Out32(dc_base_addr + 4 * 31, 0);
    for (i = 0; i < 31; i++) {
        Xil_Out32(dc_base_addr + 4 * i, dc_regs[i]);
    }
    Xil_Out32(dc_base_addr + 4 * 31, dc_regs[31]);

    for (i = 0; i < 36; i++) {
        u32 v = Xil_In32(dc_base_addr + 4 * i);
        if (v != dc_regs[i]) {
            printf("regIdx: %d, read: %x, shoud be: %x\n\r", i, v, dc_regs[i]);
        }
    }

    Xil_Out32(launch_base_addr + 4 * 3, 0);
    for (i = 0; i < 3; i++) {
        Xil_Out32(launch_base_addr + 4 * i, launch_regs[i]);
    }
    Xil_Out32(launch_base_addr + 4 * 3, launch_regs[3]);

    for (i = 0; i < 4; i++) {
        u32 v = Xil_In32(launch_base_addr + 4 * i);
        if (v != launch_regs[i]) {
            printf("regIdx: %d, read: %x, shoud be: %x\n\r", i, v, launch_regs[i]);
        }
    }

    print("Done mmio\n\r");

    return Status;

}

int program_launch() {
    s32 Status = XST_SUCCESS;
    sint32 i;
    Xil_Out32(launch_base_addr + 4 * 3, 0);
    for (i = 0; i < 3; i++) {
        Xil_Out32(launch_base_addr + 4 * i, launch_regs[i]);
    }
    for (i = 0; i < 3; i++) {
        u32 v = Xil_In32(launch_base_addr + 4 * i);
        if (v != launch_regs[i]) {
            printf("regIdx: %d, read: %x, shoud be: %x\n\r", i, v, launch_regs[i]);
        }
    }
    Xil_Out32(launch_base_addr + 4 * 3, launch_regs[3]);
    Xil_Out32(launch_base_addr + 4 * 3, 0);
    return Status;
}


int main()
{
    init_platform();

    print("Hello World\n\r");
    print("Successfully ran Hello World application");

    dc_test();
    // cleanup_platform();
    return 0;
}
