#!/bin/bash
colcon build --packages-up-to rosidl_typesupport_microxrcedds_c --metas src --cmake-args -DBUILD_TESTING=OFF -DBUILD_SHARED_LIBS=ON $@

set +o nounset
. install/local_setup.bash
set -o nounset

colcon build --packages-up-to rclc --metas src --cmake-args -DBUILD_TESTING=OFF -DBUILD_SHARED_LIBS=ON $@

set +o nounset
. install/local_setup.bash
set -o nounset

colcon build --metas src --cmake-args -DBUILD_TESTING=OFF -DBUILD_SHARED_LIBS=ON $@
