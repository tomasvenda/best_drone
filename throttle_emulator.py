#!/usr/bin/env python3

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Joy

import sys
import termios
import tty
import select


class JoyThrottleEmulator(Node):
    def __init__(self):
        super().__init__('joy_throttle_emulator')

        self.pub = self.create_publisher(Joy, '/joy', 10)

        self.throttle = 0.0

        self.axes = [0.0] * 8
        self.buttons = [0] * 12

        self.timer = self.create_timer(0.05, self.loop)

        # IMPORTANT: set raw mode ONCE
        self.settings = termios.tcgetattr(sys.stdin)
        tty.setcbreak(sys.stdin.fileno())

        self.get_logger().info("Keyboard /joy emulator started")

    def get_key(self):
        rlist, _, _ = select.select([sys.stdin], [], [], 0.0)
        if not rlist:
            return None
        return sys.stdin.read(1)

    def clamp(self, v):
        return max(0.0, min(100.0, v))

    def handle_key(self, key):
        if key is None:
            return

        # Arrow keys = ESC sequence
        if key == '\x1b':
            k2 = self.get_key()
            k3 = self.get_key()

            if k2 == '[':
                if k3 == 'A':   # up
                    self.throttle += 1.0
                elif k3 == 'B': # down
                    self.throttle -= 1.0

        elif key in ['w', 'W']:
            self.throttle += 5.0

        elif key in ['s', 'S']:
            self.throttle -= 5.0

        elif key in ['q', 'Q']:
            self.throttle += 0.1

        elif key in ['a', 'A']:
            self.throttle -= 0.1

        self.throttle = self.clamp(self.throttle)

    def publish_joy(self):
        msg = Joy()

        self.axes[1] = self.throttle / 100.0

        msg.axes = self.axes
        msg.buttons = self.buttons

        self.pub.publish(msg)

    def loop(self):
        key = self.get_key()
        self.handle_key(key)

        self.publish_joy()

        print(f"\rThrottle: {self.throttle:.1f}%   ", end='', flush=True)


def main():
    rclpy.init()
    node = JoyThrottleEmulator()

    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, node.settings)
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
