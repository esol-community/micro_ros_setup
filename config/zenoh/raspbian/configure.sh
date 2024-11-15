#! /bin/bash

. $PREFIX/config/utils.sh

function help {
      echo "Configure script need an argument."
      echo "   --transport -t       unicast or serial"
      echo "   --dev -d             connect zenohd string descriptor in a serial-like transport"
      echo "   --ip -i              connect zenohd IP in a network-like transport"
      echo "   --port -p            connect zenohd port in a network-like transport"
}

pushd $FW_TARGETDIR >/dev/null
    rm -rf mcu_ws/*
    cp raspbian_apps/toolchain.cmake mcu_ws/
    cp -r rmw_zenoh_pico/rmw_zenoh_pico mcu_ws/uros/
    cp -r rmw_zenoh_pico/rmw_zenoh_pico/demo/uros/* raspbian_apps/
    curl -s https://raw.githubusercontent.com/ros2/ros2/jazzy/ros2.repos |\
        ros2 run micro_ros_setup yaml_filter.py raspbian_apps/$CONFIG_NAME/ros2_repos.filter > ros2.repos
    vcs import --input ros2.repos mcu_ws/ && rm ros2.repos

    if [ -d mcu_ws/ros2/rosidl ]; then
        touch mcu_ws/ros2/rosidl/rosidl_typesupport_introspection_c/COLCON_IGNORE
        touch mcu_ws/ros2/rosidl/rosidl_typesupport_introspection_cpp/COLCON_IGNORE
    fi

    vcs import --input raspbian_apps/$CONFIG_NAME/app.repos mcu_ws/
    if [ -d raspbian_apps/$CONFIG_NAME/app ]; then
        cp -r raspbian_apps/$CONFIG_NAME/app mcu_ws/
    fi
    cp raspbian_apps/$CONFIG_NAME/colcon.meta mcu_ws/
    cp raspbian_apps/$CONFIG_NAME/app_info.sh mcu_ws/

    # local patches (2024.08.29)
    if [ -d mcu_ws/uros/zenohpico ] ; then
        git apply --directory=mcu_ws/uros/zenohpico \
            $PREFIX/config/$RTOS/patches/zenohpico/*
    fi

    if [ -d mcu_ws/uros/rosidl_typesupport_microxrcedds ] ; then
        git apply --directory=mcu_ws/uros/rosidl_typesupport_microxrcedds \
            $PREFIX/config/$RTOS/patches/rosidl_typesupport_microxrcedds/*
    fi

    if [ -d mcu_ws/uros/rcutils ] ; then
        git apply --directory=mcu_ws/uros/rcutils \
            $PREFIX/config/$RTOS/patches/rcutils/*
    fi

    # import application program
    if [ -d bin ]; then
        rm -rf bin/*
    else
        mkdir -p bin
    fi
    if [ -d raspbian_apps/$CONFIG_NAME/bin ]; then
        cp -r raspbian_apps/$CONFIG_NAME/bin mcu_ws/
    fi
popd >/dev/null

# update configure for cmake parameter
if [ "$UROS_TRANSPORT" == "unicast" ]; then
    update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_TRANSPORT="$UROS_TRANSPORT

    if [ -n $UROS_AGENT_IP ]; then
	update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_CONNECT="$UROS_AGENT_IP
    fi

    if [ -n $UROS_AGENT_PORT ]; then
	update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_CONNECT_PORT="$UROS_AGENT_PORT
    fi

    echo "Configured $UROS_TRANSPORT mode for zenoh-pico"

elif [ "$UROS_TRANSPORT" == "serial" ]; then
    update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_TRANSPORT="$UROS_TRANSPORT
    # T.D.B
else
    help
    exit 1
fi
