# ============================================================
# Stage 1: Build the workspace
# ============================================================
FROM ros:humble AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build tools and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-colcon-common-extensions \
    python3-vcstool \
    ros-humble-rclcpp \
    ros-humble-rclcpp-lifecycle \
    ros-humble-std-msgs \
    ros-humble-geometry-msgs \
    ros-humble-tf2 \
    ros-humble-tf2-msgs \
    ros-humble-tf2-ros \
    ros-humble-tf2-geometry-msgs \
    ros-humble-visualization-msgs \
    ros-humble-sensor-msgs \
    ros-humble-lifecycle-msgs \
    ros-humble-launch \
    ros-humble-launch-ros \
    ros-humble-rosidl-default-generators \
    ros-humble-rosidl-default-runtime \
    ros-humble-rclpy \
    ros-humble-ros2cli \
    ros-humble-rqt-gui \
    ros-humble-rqt-gui-cpp \
    ros-humble-qt-gui-cpp \
    ros-humble-rclcpp-components \
    ros-humble-pluginlib \
    qtbase5-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy the workspace source
WORKDIR /ws
COPY src/ src/

# Install any remaining rosdep dependencies (ignore test-only deps that may be unavailable)
RUN . /opt/ros/humble/setup.sh && \
    rosdep update && \
    (rosdep install --from-paths src --ignore-src -r -y || true)

# Build the workspace
RUN . /opt/ros/humble/setup.sh && \
    colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release

# ============================================================
# Stage 2: Runtime image
# ============================================================
FROM ros:humble

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-rclcpp \
    ros-humble-rclcpp-lifecycle \
    ros-humble-std-msgs \
    ros-humble-geometry-msgs \
    ros-humble-tf2 \
    ros-humble-tf2-msgs \
    ros-humble-tf2-ros \
    ros-humble-lifecycle-msgs \
    ros-humble-launch \
    ros-humble-launch-ros \
    ros-humble-rosidl-default-runtime \
    ros-humble-rclpy \
    ros-humble-ros2cli \
    ros-humble-ros2lifecycle \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ws

# Copy the built workspace from builder
COPY --from=builder /ws/install/ install/

# Copy NatNet shared library and register it
COPY src/mocap4ros2_optitrack/mocap4r2_optitrack_driver/NatNetSDK/lib/libNatNet.so /usr/local/lib/
RUN ldconfig

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Default environment variables (override with docker run -e)
ENV SERVER_IP=192.168.1.130
ENV LOCAL_IP=0.0.0.0
ENV CONNECTION_TYPE=Unicast
ENV RIGID_BODY_IDS=

ENTRYPOINT ["/entrypoint.sh"]
