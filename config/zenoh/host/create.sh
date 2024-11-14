# populate the workspace
mkdir -p src

ros2 run micro_ros_setup create_ws.sh src $PREFIX/config/$RTOS/client_ros2_packages.txt $PREFIX/config/$RTOS/$PLATFORM/client_host_packages.repos

# add appropriate colcon.meta
cp $PREFIX/config/$RTOS/$PLATFORM/client-host-colcon.meta src/colcon.meta

rosdep install -y --from-paths src -i src --skip-keys="$SKIP" -r

touch src/uros/rclc/rclc_examples/COLCON_IGNORE
touch src/uros/rclc/rclc_lifecycle/COLCON_IGNORE

# local patches (2024.08.29)
if [ -d src/uros/zenohpico ] ; then
    git apply --directory=src/uros/zenohpico \
	$PREFIX/config/$RTOS/patches/zenohpico/*
fi

if [ -d src/uros/rosidl_typesupport_microxrcedds ] ; then
    git apply --directory=src/uros/rosidl_typesupport_microxrcedds \
	$PREFIX/config/$RTOS/patches/rosidl_typesupport_microxrcedds/*
fi
