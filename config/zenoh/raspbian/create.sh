#! /bin/bash

pushd $FW_TARGETDIR/$DEV_WS_DIR >/dev/null
    if [ $OPTION == "bookworm_v12" ]; then
	TOOLCHAIN_URL="https://sourceforge.net/projects/raspberry-pi-cross-compilers/files/Raspberry%20Pi%20GCC%20Cross-Compiler%20Toolchains/Bookworm/GCC%2012.2.0/Raspberry%20Pi%201%2C%20Zero/cross-gcc-12.2.0-pi_0-1.tar.gz/download"
    else
        echo "Platform not supported."
        exit 1
    fi
    # curl -o ~/xcompiler.tar.gz -L $TOOLCHAIN_URL
    mkdir xcompiler
    tar xf ~/xcompiler.tar.gz -C xcompiler --strip-components 1
    # rm xcompiler.tar.gz
popd >/dev/null

pushd $FW_TARGETDIR >/dev/null
    git clone -b jazzy https://github.com/micro-ROS/raspbian_apps.git
popd >/dev/null

# get rmw_zenoh_pico repository from local strage
if [ ! -v RMW_ZENOH_PICO_PATH ] ; then
    export RMW_ZENOH_PICO_PATH="../rmw_zenoh_pico"
fi

if [ -d $RMW_ZENOH_PICO_PATH/rmw_zenoh_pico/demo/uros ] ; then
    find $RMW_ZENOH_PICO_PATH/rmw_zenoh_pico/demo/uros/* -type d -exec cp -a {} ./firmware/raspbian_apps \;
fi
