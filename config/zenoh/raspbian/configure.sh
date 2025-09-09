#! /bin/bash

. $PREFIX/config/utils.sh

function help {
      echo "Configure script need an argument."
      echo "   --transport -t       unicast or serial"
      echo "   --dev -d             connect zenohd string descriptor in a serial-like transport"
      echo "   --ip -i              connect zenohd IP in a network-like transport or serial option"
      echo "   --port -p            connect zenohd port in a network-like transport"
}

pushd $FW_TARGETDIR >/dev/null

    # get raspbian_apps repository from local strage
    git clone -b jazzy https://github.com/micro-ROS/raspbian_apps.git

    rm -rf mcu_ws/*
    cp raspbian_apps/toolchain.cmake mcu_ws/

    mkdir mcu_ws/uros

    # get rmw_zenoh_pico repository from local strage
    if [ ! -v RMW_ZENOH_PICO_PATH ] ; then
        git clone https://github.com/esol-community/rmw_zenoh_pico -b main mcu_ws/uros/rmw_zenoh_pico
    else
        cp -a $RMW_ZENOH_PICO_PATH mcu_ws/uros/rmw_zenoh_pico
    fi

    cp -a mcu_ws/uros/rmw_zenoh_pico/examples/microros/uros/* raspbian_apps/

    # get zenoh_pico repository from git or local strage
    if [ ! -v ZENOH_PICO_PATH ] ; then
        git clone https://github.com/eclipse-zenoh/zenoh-pico.git -b 1.4.0 mcu_ws/uros/zenohpico
    else
        cp -a $ZENOH_PICO_PATH mcu_ws/uros/zenohpico
    fi

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
	cp -a mcu_ws/uros/rmw_zenoh_pico/examples/microros/app/$CONFIG_NAME/* mcu_ws/app/.
    fi
    cp raspbian_apps/$CONFIG_NAME/colcon.meta mcu_ws/
    cp raspbian_apps/$CONFIG_NAME/app_info.sh mcu_ws/

    # local patches (2025.05.25)
    if [ -d mcu_ws/uros/rmw_zenoh_pico/patches/${ROS_DISTRO}/zenohpico ] ; then
	echo apply zenohpico patch...
	pushd mcu_ws/uros/zenohpico > /dev/null
        git apply ${FW_TARGETDIR}/mcu_ws/uros/rmw_zenoh_pico/patches/${ROS_DISTRO}/zenohpico/* || true
	popd > /dev/null
    fi

    if [ -d mcu_ws/uros/rmw_zenoh_pico/patches/${ROS_DISTRO}/rosidl_typesupport_microxrcedds ] ; then
	echo apply rosidl_typesupport_microxrcedds...
	pushd mcu_ws/uros/rosidl_typesupport_microxrcedds > /dev/null
        git apply ${FW_TARGETDIR}/mcu_ws/uros/rmw_zenoh_pico/patches/${ROS_DISTRO}/rosidl_typesupport_microxrcedds/* || true
	popd > /dev/null
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
    echo UROS_TRANSPORT   : $UROS_TRANSPORT
    echo UROS_AGENT_PORT  : $UROS_AGENT_PORT
    echo UROS_AGENT_IP    : $UROS_AGENT_IP
    echo LISTEN_IP        : $LISTEN_IP
    echo CONNECT_IP       : $CONNECT_IP
    echo CONNECT_PORT     : $CONNECT_PORT
    echo FEATURE_INTEREST : $FEATURE_INTEREST

    update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_TRANSPORT_TYPE="$UROS_TRANSPORT

    if [ -n "$LISTEN_PORT" ] ; then
        update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_LISTEN_PORT="$LISTEN_PORT
    fi

    if [ -n "$LISTEN_IP" ] ; then
        update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_LISTEN="$LISTEN_IP
    fi

    if [ -n "$UROS_AGENT_PORT" ]; then
        update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_CONNECT_PORT="$UROS_AGENT_PORT
    else
	if [ -n "$CONNECT_IP" ]; then
            update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_CONNECT_PORT="$CONNECT_IP
	fi
    fi

    if [ -n "$UROS_AGENT_IP" ]; then
        update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_CONNECT="$UROS_AGENT_IP
    else
	if [ -n "$CONNECT_PORT" ]; then
            update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_CONNECT="$CONNECT_PORT
	fi
    fi

    if [ "$FEATURE_INTEREST" == "on" ]; then
        update_meta "zenohpico" "Z_FEATURE_INTEREST=1"
    else
        update_meta "zenohpico" "Z_FEATURE_INTEREST=0"
    fi

    echo "Configured $UROS_TRANSPORT mode for zenoh-pico"

elif [ "$UROS_TRANSPORT" == "mcast" ]; then

    echo UROS_TRANSPORT    : $UROS_TRANSPORT
    echo UROS_AGENT_PORT   : $UROS_AGENT_PORT
    echo UROS_AGENT_DEVICE : $UROS_AGENT_DEVICE
    echo UROS_AGENT_IP     : $UROS_AGENT_IP
    echo MCAST_PORT        : $MCAST_PORT
    echo MCAST_IP          : $MCAST_IP
    echo MCAST_DEV         : $MCAST_DEV

    update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_TRANSPORT_TYPE="$UROS_TRANSPORT

    if [ -n "$UROS_AGENT_DEVICE" ] ; then
	update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_MCAST_DEV="$UROS_AGENT_DEVICE
    else
	if [ -n "$MCAST_DEV" ]; then
	    update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_MCAST_DEV="$MCAST_DEV
	fi
    fi

    if [ -n "$UROS_AGENT_PORT" ]; then
	update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_MCAST_PORT="$UROS_AGENT_PORT
    else
	if [ -n "$MCAST_PORT" ]; then
	    update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_MCAST_PORT="$MCAST_PORT
	fi
    fi

    if [ -n "$UROS_AGENT_IP" ]; then
	update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_MCAST="$UROS_AGENT_IP
    else
	if [ -n "$MCAST_IP" ]; then
	    update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_MCAST="$MCAST_IP
	fi
    fi

echo "Configured $UROS_TRANSPORT mode for zenoh-pico"

elif [ "$UROS_TRANSPORT" == "serial" ]; then

    echo UROS_TRANSPORT    : $UROS_TRANSPORT
    echo UROS_AGENT_PORT   : $UROS_AGENT_PORT
    echo UROS_AGENT_DEVICE : $UROS_AGENT_DEVICE
    echo SERIAL_DEVICE     : $SERIAL_DEVICE
    echo SERIAL_PARAM      : $SERIAL_PARAM

    update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_TRANSPORT_TYPE="$UROS_TRANSPORT

    if [ -n "$UROS_AGENT_DEVICE" ] ;then
	update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_SERIAL_DEVICE="$UROS_AGENT_DEVICE
    else
	if [ -n "$SERIAL_DEVICE" ]; then
	    update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_SERIAL_DEVICE="$SERIAL_DEVICE
	fi
    fi

    if [ -n "$UROS_AGENT_PORT" ]; then
	update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_SERIAL_PARAM="$UROS_AGENT_PORT
    else
	if [ -n "$SERIAL_PARAM" ]; then
	    update_meta "rmw_zenoh_pico" "RMW_ZENOH_PICO_SERIAL_PARAM="$SERIAL_PARAM
	fi
    fi

    echo "Configured $UROS_TRANSPORT mode for zenoh-pico"

else
    help
    exit 1
fi
