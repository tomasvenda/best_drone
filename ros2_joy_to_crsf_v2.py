#!/usr/bin/env python3

import time
import serial

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Joy


SERIAL_PORT = "/dev/ttyACM0"
BAUD_RATE = 115200

SEND_PERIOD_S = 0.01  # 10 ms = 100 Hz

CRSF_ADDRESS = 0xC8
CRSF_FRAMETYPE_RC_CHANNELS_PACKED = 0x16


def crc8_dvb_s2(data: bytes) -> int:
    crc = 0
    for b in data:
        crc ^= b
        for _ in range(8):
            if crc & 0x80:
                crc = ((crc << 1) ^ 0xD5) & 0xFF
            else:
                crc = (crc << 1) & 0xFF
    return crc


def us_to_crsf_ticks(us: int) -> int:
    us = max(1000, min(2000, int(us)))
    return int(round((us - 1500) * 8 / 5 + 992))


def pack_channels_us(channels_us):
    if len(channels_us) != 16:
        raise ValueError("Need exactly 16 channels")

    channels = [us_to_crsf_ticks(ch) for ch in channels_us]

    payload = bytearray()
    bit_buffer = 0
    bit_count = 0

    for ch in channels:
        bit_buffer |= (ch & 0x7FF) << bit_count
        bit_count += 11

        while bit_count >= 8:
            payload.append(bit_buffer & 0xFF)
            bit_buffer >>= 8
            bit_count -= 8

    if len(payload) != 22:
        raise RuntimeError(f"Bad payload length: {len(payload)}")

    return payload


def make_crsf_rc_frame(channels_us):
    payload = pack_channels_us(channels_us)

    frame = bytearray()
    frame.append(CRSF_ADDRESS)
    frame.append(len(payload) + 2)
    frame.append(CRSF_FRAMETYPE_RC_CHANNELS_PACKED)
    frame.extend(payload)
    frame.append(crc8_dvb_s2(frame[2:]))

    return frame


def clamp(x, lo, hi):
    return max(lo, min(hi, x))


def axis_to_pwm(axis_value, center=1500, scale=500, invert=False):
    v = -axis_value if invert else axis_value
    return int(clamp(center + scale * v, 1000, 2000))


def throttle_axis_to_pwm(axis_value, invert=False):
    v = -axis_value if invert else axis_value

    # Assumes axis range is approximately -1 to +1.
    # This maps -1 -> 1000, 0 -> 1500, +1 -> 2000.
    return int(clamp(1500 + 500 * v, 1000, 2000))


class JoyToCRSF(Node):
    def __init__(self):
        super().__init__("joy_to_crsf_esp32")

        self.ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=0.01)

        # Safe default channel values
        self.channels = [
            1500,  # ch1 roll
            1500,  # ch2 pitch
            1000,  # ch3 throttle
            1500,  # ch4 yaw
            1000,  # ch5 arm/disarm
            1500,  # ch6
            1500,  # ch7
            1500,  # ch8
            1500,  # ch9
            1500,  # ch10
            1500,  # ch11
            1500,  # ch12
            1500,  # ch13
            1500,  # ch14
            1500,  # ch15
            1500,  # ch16
        ]

        self.last_joy_time = time.monotonic()
        self.last_print_time = 0.0

        self.sub = self.create_subscription(
            Joy,
            "/joy",
            self.joy_callback,
            10
        )

        # Send CRSF continuously at 100 Hz.
        self.timer = self.create_timer(SEND_PERIOD_S, self.send_frame)

        self.get_logger().info(
            f"Sending CRSF to ESP32 on {SERIAL_PORT} at {BAUD_RATE} baud"
        )
        self.get_logger().info(
            "ESP32 forwards to Ranger Nano on GPIO16 at 420000 baud"
        )
        self.get_logger().info(
            "Safety: no /joy for 0.5 s => throttle low and disarmed"
        )

    def joy_callback(self, msg: Joy):
        self.last_joy_time = time.monotonic()

        # Mapping used here:
        # ch1 roll     = axes[0]
        # ch2 pitch    = axes[1]
        # ch3 throttle = axes[2]
        # ch4 yaw      = axes[3]
        #
        # You may need to adjust axes depending on your joystick.

        if len(msg.axes) >= 4:
            self.channels[0] = axis_to_pwm(msg.axes[0], invert=True)       # roll
            self.channels[1] = axis_to_pwm(msg.axes[1], invert=False)      # pitch
            self.channels[2] = throttle_axis_to_pwm(msg.axes[2], invert=False)
            self.channels[3] = axis_to_pwm(msg.axes[3], invert=False)      # yaw

        # Arm on button[0].
        # Hold button[0] to arm; release to disarm.
        if len(msg.buttons) > 0 and msg.buttons[0] == 1:
            self.channels[4] = 2000
        else:
            self.channels[4] = 1000

    def send_frame(self):
        # Computer-side failsafe
        if time.monotonic() - self.last_joy_time > 0.5:
            self.channels[2] = 1000
            self.channels[4] = 1000


        frame = make_crsf_rc_frame(self.channels)
        self.ser.write(frame)
        # print('--------------------')

        now = time.monotonic()
        if now - self.last_print_time > 0.5:
            self.last_print_time = now
            self.get_logger().info(
                f"channels_us={self.channels[:8]} frame_len={len(frame)}"
            )

    def destroy_node(self):
        # On shutdown, send throttle low + disarm for 300 ms.
        self.channels[2] = 1000
        self.channels[4] = 1000

        try:
            for _ in range(30):
                self.ser.write(make_crsf_rc_frame(self.channels))
                time.sleep(0.01)
            self.ser.close()
        except Exception:
            pass

        super().destroy_node()


def main():
    rclpy.init()
    node = JoyToCRSF()

    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()
