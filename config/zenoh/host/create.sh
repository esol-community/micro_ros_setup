# populate the workspace
mkdir -p src

echo ros2 run micro_ros_setup create_ws.sh src $PREFIX/config/$RTOS/client_ros2_packages.txt $PREFIX/config/$RTOS/$PLATFORM/client_host_packages.repos

ros2 run micro_ros_setup create_ws.sh src $PREFIX/config/$RTOS/client_ros2_packages.txt $PREFIX/config/$RTOS/$PLATFORM/client_host_packages.repos

# add appropriate colcon.meta
cp $PREFIX/config/$RTOS/$PLATFORM/client-host-colcon.meta src/colcon.meta

rosdep install -y --from-paths src -i src --skip-keys="$SKIP" -r

touch src/uros/rclc/rclc_examples/COLCON_IGNORE
touch src/uros/rclc/rclc_lifecycle/COLCON_IGNORE

# get rmw_zenoh_pico repository from git or local strage
if [ ! -v RMW_ZENOH_PICO_PATH ] ; then
    git clone https://github.com/esol-community/rmw_zenoh_pico -b jazzy src/uros/rmw_zenoh_pico
else
    cp -a $RMW_ZENOH_PICO_PATH src/uros/rmw_zenoh_pico
fi

# copy demo application
cp -a src/uros/rmw_zenoh_pico/examples/microros/app src/uros/rmw_zenoh_pico/rmw_zenoh_pico/.
cp -a src/uros/rmw_zenoh_pico/examples/microros/host/* src/uros/rmw_zenoh_pico/rmw_zenoh_pico/app/.

# get zenoh_pico repository from git or local strage
if [ ! -v ZENOH_PICO_PATH ] ; then
    git clone https://github.com/eclipse-zenoh/zenoh-pico.git -b 1.4.0 src/uros/zenohpico
else
    cp -a $ZENOH_PICO_PATH src/uros/zenohpico
fi

# local patches (2025.05.25)
if [ -d src/uros/rmw_zenoh_pico/patches/${ROS_DISTRO}/zenohpico ] && [ ! -v ZENOH_PICO_PATH ] ; then
    echo apply patch for zenohpico
    git apply --directory=src/uros/zenohpico \
	src/uros/rmw_zenoh_pico/patches/${ROS_DISTRO}/zenohpico/* || true
fi

if [ -d src/uros/rmw_zenoh_pico/patches/${ROS_DISTRO}/rosidl_typesupport_microxrcedds ] ; then
    echo apply patch for rosidl_typesupport_microxrcedds
    git apply --directory=src/uros/rosidl_typesupport_microxrcedds \
	src/uros/rmw_zenoh_pico/patches/${ROS_DISTRO}/rosidl_typesupport_microxrcedds/* || true
    touch src/uros/rosidl_typesupport_microxrcedds/test/COLCON_IGNORE
fi
