#!/bin/bash
set -e

# Source ROS 2 and workspace
source /opt/ros/humble/setup.bash
source /ws/install/setup.bash

# Disable FastDDS shared memory transport so DDS works between container and host
cat > /tmp/fastdds_no_shm.xml <<'XMLEOF'
<?xml version="1.0" encoding="UTF-8" ?>
<dds>
    <profiles xmlns="http://www.eprosima.com/XMLSchemas/fastRTPS_Profiles">
        <transport_descriptors>
            <transport_descriptor>
                <transport_id>udp_transport</transport_id>
                <type>UDPv4</type>
            </transport_descriptor>
        </transport_descriptors>
        <participant profile_name="participant_profile" is_default_profile="true">
            <rtps>
                <userTransports>
                    <transport_id>udp_transport</transport_id>
                </userTransports>
                <useBuiltinTransports>false</useBuiltinTransports>
            </rtps>
        </participant>
    </profiles>
</dds>
XMLEOF
export FASTRTPS_DEFAULT_PROFILES_FILE=/tmp/fastdds_no_shm.xml

# Environment variable defaults
SERVER_IP="${SERVER_IP:-192.168.1.130}"
LOCAL_IP="${LOCAL_IP:-0.0.0.0}"
CONNECTION_TYPE="${CONNECTION_TYPE:-Unicast}"
RIGID_BODY_IDS="${RIGID_BODY_IDS:-}"

# Build the rigid_body_ids YAML list
if [ -n "$RIGID_BODY_IDS" ]; then
  # Convert comma-separated "1,4" to YAML list ["1", "4"]
  RB_IDS_YAML=$(echo "$RIGID_BODY_IDS" | sed 's/[[:space:]]//g' | awk -F',' '{
    printf "["
    for(i=1;i<=NF;i++){
      if(i>1) printf ", "
      printf "\"%s\"", $i
    }
    printf "]"
  }')
else
  RB_IDS_YAML="[]"
fi

# Generate runtime config from environment variables
cat > /tmp/optitrack_params.yaml <<EOF
mocap4r2_optitrack_driver_node:
  ros__parameters:
    connection_type: "${CONNECTION_TYPE}"
    server_address: "${SERVER_IP}"
    local_address: "${LOCAL_IP}"
    multicast_address: "239.255.42.99"
    server_command_port: 1510
    server_data_port: 1511
    rigid_body_name: "ground"
    rigid_body_ids: ${RB_IDS_YAML}
    lastFrameNumber: 0
    frameCount: 0
    droppedFrameCount: 0
    n_markers: 0
    n_unlabeled_markers: 0
    qos_history_policy: "keep_all"
    qos_reliability_policy: "best_effort"
    qos_depth: 10
EOF

echo "Starting OptiTrack driver with:"
echo "  SERVER_IP=${SERVER_IP}"
echo "  LOCAL_IP=${LOCAL_IP}"
echo "  CONNECTION_TYPE=${CONNECTION_TYPE}"
echo "  RIGID_BODY_IDS=${RB_IDS_YAML}"

# Launch the driver (runs in background)
ros2 launch mocap4r2_optitrack_driver optitrack2.launch.py \
  config_file:=/tmp/optitrack_params.yaml &
LAUNCH_PID=$!

# Wait for the node to be available, then activate it
echo "Waiting for node to be configured..."
sleep 5

for i in $(seq 1 10); do
  if ros2 service list 2>/dev/null | grep -q "/mocap4r2_optitrack_driver_node/change_state"; then
    echo "Activating node..."
    ros2 service call /mocap4r2_optitrack_driver_node/change_state \
      lifecycle_msgs/srv/ChangeState "{transition: {id: 3}}"
    echo "Node activated — publishing on /rigid_bodies and /markers"
    break
  fi
  echo "  Waiting for node... (attempt $i/10)"
  sleep 2
done

# Keep the container alive
wait $LAUNCH_PID
