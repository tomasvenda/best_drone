# Instructions

## Docker Container

```bash
ip addr show
```

### Wired Ethernet

```bash
sudo docker run --rm --network host \
  -e SERVER_IP=192.168.1.129 \
  -e LOCAL_IP=192.168.1.134 \
  -e RIGID_BODY_IDS=76 \
  vvipu/mocap4r2_optitrack
```

### Wireless Connection

```bash
sudo docker run --rm --network host \
  -e SERVER_IP=192.168.1.129 \
  -e LOCAL_IP=192.168.1.116 \
  -e RIGID_BODY_IDS=76 \
  vvipu/mocap4r2_optitrack
```

```bash
docker stop $(docker ps -q)
```

## ROS2 Topics

```bash
source ~/dtu/optitrack_ros2_humble/install/setup.bash
```

```bash
ros2 topic list
```

```bash
ros2 topic echo /rigid_bodies
```

```bash
ros2 topic echo /rigid_body_76/pose
```

## Drone Communication

```bash
/usr/bin/python3 ros2_joy_to_crsf_v2.py
```

## Joystick

```bash
source ~/dtu/optitrack_ros2_humble/install/setup.bash
ros2 run joy joy_node
```
