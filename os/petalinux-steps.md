1. Export xsa file from vivado
2. Use vitis to create a linux platform with the exported xsa file as input
3. Vitis will create a folder: [vitis platform dir]/hw/sdt, this folder will be used in 7. Inside this folder, there should be a pl.dtsi file, it will be used in 13
4. Source settings.sh in the directory where petalinux is installed
5. Download the bsp (board support package) from the petalinux download page from xilinx
6. Run "petalinux-create -t project -s /path/to/bsp" to create a petalinux project directory based on the bsp
7. Run "petalinux-config --get-hw-description /path/to/[vitis platform dir]/hw/sdt" to do basic configuration
8. A terminal gui opens up, do the following:
   --DTG Settings->Kernel Bootargs->Uncheck "generate bookargs automatically"->
     Put "earlycon console=ttyPS0,115200 clk_ignore_unused uio_pdrv_genirq.of_id=generic-uio root=/dev/mmcblk0p2 rw rootwait" as the bootarg
   --FPGA Manager->Check FPGA Manager
   --Image Packaging Configurations->Root filesystem type->Select EXT4 (SD/eMMC/SATA/USB).
     Additionally, uncheck "Copy final images to tftpboot"
9. Run "petalinux-config -c kernel" to configure kernel
10. A terminal gui opens in a new shell window, check the following settings:
    --Device Drivers->Userspace I/O drivers->
      Change "Userspace I/O platform driver with generic IRQ handling" and 
      "Userspace platform driver with generic irq and dynamic memo" from "M" to fully selected
11. Run "petalinux-config -c rootfs" to configure root filesystem
12. A terminal gui opens up, check the following settings: (these are quality of life settings)
    --Image Features->check package-management
    --Filesystem Packages->base->opkg->check opkg
    --Go through the list and check everything you use for linux development
13. Modify [petalinux project dir]/project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi, do the following:
    --There should be "/ {}" prepared for you to override existing device tree setups
    --In pl.dtsi, you should recognize the blocks for your axi ips in pl
    --Copy the text that starts with "ambda_pl" in pl.dtsi to system-user.dtsi, put it into the "/ {}": "/ {'amba_pl...'}" 
    --Change the compatible="[place holder for driver]" in your axi ips to compatible="generic-uio"
    --Add 
    "&{/axi/mmc@ff170000} {
        status = "okay";
        disable-wp;
    };"
    below "/ {'amba_pl...}"
14. Run "petalinux-build" to build
15. Run "petalinux-package --boot --fsbl ./images/linux/zynqmp_fsbl.elf --fpga ./images/linux/system.bit --u-boot" to package
16. Run '''petalinux-package --wic --bootfiles "BOOT.BIN image.ub system.dtb boot.scr" \
           --rootfs-file ./images/linux/rootfs.tar.gz''' to build the sd card image
17. You should see [petalinux dir]/images/linux/petalinux-sdimage/wic, dd it to your sd card
18. After the kernel boots, go check /sys/class/uio/uio?/maps/map0/{name,addr}, 
    cat them and you should see your ip name and memory mapped addresses
19. If pl is not programmed, run "sudo fpgautil -b [bitstream] -f Full" to program pl
19. Use devmem to try read/write your ip


Useful posts:
https://www.hackster.io/engrinam0077/zcu104-mpsoc-development-petalinux-2024-2-basic-tutorial-c82b8d
https://www.reddit.com/r/FPGA/comments/1mgmbyh/start_to_finish_a_plps_design_guide_for_zynq/
    
