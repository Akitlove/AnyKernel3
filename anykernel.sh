# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=EAS Kernel for the OnePlus3/3T
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=1
device.name1=oneplus3
device.name2=oneplus3t
device.name3=OnePlus3
device.name4=OnePlus3T
device.name5=
supported.versions=
supported.patchlevels=
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 755 755 $ramdisk/init* $ramdisk/sbin;

## AnyKernel install
dump_boot;
## Alert of unsupported OOS
oos_ver=$(file_getprop /system/build.prop ro.build.ota.versionname)
if [ $oos_ver ]; then
    ui_print " ";
    ui_print "  Warning: incompatible ROM detected.";
    ui_print " ";
    ui_print "  This Kernel version does not support";
    ui_print "  OxygenOS. Please select the OxygenOS";
    ui_print "  version of this Kernel to proceed.";
    ui_print " ";
    ui_print "  - Installer will abort now.";
    exit 0
fi;

## start system changes
mount -o remount,rw /system;

## Alert of insufficient /system space
avail_space=`df -kh /system | grep -v "Filesystem" | awk '{ print $5 }' | cut -d'%' -f1`
if [ "$avail_space" == "100" ]; then
    ui_print " ";
    ui_print "  Warning: your /system partition is full.";
    ui_print " ";
    ui_print "  This Kernel needs at least 10 MB free space";
    ui_print "  on your /system partition."
    ui_print " ";
    ui_print "  Do you want to delete 'G-Play Movies' now?";
    ui_print " ";
    ui_print "  Press: Volume Up [YES] || Volume Down [NO]";
    # keycheck to delete system-app
    /tmp/anykernel/tools/keycheck; KVAR=$?
    if [ $KVAR -eq 41 ]; then
        ui_print " ";
        ui_print "  - Installer will abort now.";
        exit 0
    elif [ $KVAR -eq 42 ]; then
        ui_print " ";
        ui_print "  - Deleting Google Play Movies...";
        rm -rf /system/app/Videos;
        rm -rf /data/data/com.google.android.videos;
        rm -f /data/dalvik-cache/*/*Videos.apk* ;
    fi;
fi;

# insert custom inits
if [ -f /system/vendor/etc/init/hw/init.qcom.rc ]; then
    ui_print " ";
    ui_print "  - Injecting in /vendor/etc/init/hw/init.qcom.rc";
    # import mcd.rc
    cp /tmp/anykernel/ramdisk/init.mcd.rc /system/vendor/etc/init/hw/init.mcd.rc;
    insert_line /system/vendor/etc/init/hw/init.qcom.rc "init.mcd.rc" after "import /vendor/etc/init/hw/init.qcom.usb.rc" "import /vendor/etc/init/hw/init.mcd.rc";
    # import spectrum.rc
    cp /tmp/anykernel/ramdisk/init.spectrum.rc /system/vendor/etc/init/hw/init.spectrum.rc;
    replace_line /system/vendor/etc/init/hw/init.mcd.rc "import /init.spectrum.rc" "import /vendor/etc/init/hw/init.spectrum.rc";
    remove_line /system/vendor/etc/init/hw/init.qcom.rc "import /vendor/etc/init/hw/init.spectrum.rc";
    # chmod
    chmod 644 /system/vendor/etc/init/hw/init.mcd.rc;
    chmod 644 /system/vendor/etc/init/hw/init.spectrum.rc;
fi;

mount -o remount,ro /system;

## end system changes

## AnyKernel install
dump_boot;

# begin ramdisk changes

# Import mcd.rc
remove_line init.rc "init.mcd.rc";
insert_line init.rc "init.mcd.rc" after "import /init.usb.configfs.rc" "import /init.mcd.rc";

# end ramdisk changes

write_boot;
## end install
