import traceback
import sys
from datetime import datetime
import argparse
from pathlib import Path
import time
import math

import gi
gi.require_version('Gst', '1.0')
from gi.repository import Gst, GObject

# Initializes Gstreamer, it's variables, paths
Gst.init(None)

pipeline = None
bus = None

def run_pipeline(sensor_path):

    data_folder = Path(sensor_path)
    z_raw = data_folder / "in_accel_z_raw"
    y_raw = data_folder / "in_accel_y_raw"
    x_raw = data_folder / "in_accel_x_raw"
    a = 0.90 #tuning factor for the digital LPF
    sensitivity = 16384
    angle = 1
    width = 4
    # Initialising x,y,z data
    x_sensor_file = open(x_raw,'r')
    x_data_new = x_data_last = int(x_sensor_file.read())
    x_sensor_file.close()

    y_sensor_file = open(y_raw,'r')
    y_data_new = y_data_last = int(y_sensor_file.read())
    y_sensor_file.close()

    z_sensor_file = open(z_raw,'r')
    z_data_new = z_data_last = int(z_sensor_file.read())
    z_sensor_file.close()

    
    # gstreamer pipeline
    command = "rpicamsrc ! video/x-h264, width=640,height=480, framerate=30/1 ! h264parse ! omxh264dec ! textoverlay name=sensor text=hello shaded-background=yes font-desc='Serif 40' wait-text=false halignment=left valignment=top ! omxh264enc ! rtph264pay ! udpsink host=<HOST_IP_ADDRESS> port=5000 sync=false"

    pipeline = Gst.parse_launch(command)

    # get the overlay
    overlay = pipeline.get_by_name("sensor")

    # get the message bus
    bus = pipeline.get_bus()

    # Start pipeline
    pipeline.set_state(Gst.State.PLAYING)

    # Wait until error or EOS
    while True:

        # write the sensor character device data
        
        x_sensor_file = open(x_raw,'r')
        x_data_new = int(x_sensor_file.read())
        x_sensor_file.close()
        x_data_last = a*x_data_last+(1-a)*x_data_new

        y_sensor_file = open(y_raw,'r')
        y_data_new = int(y_sensor_file.read())
        y_sensor_file.close()
        y_data_last = a*y_data_last+(1-a)*y_data_new

        z_sensor_file = open(z_raw,'r')
        z_data_new = int(z_sensor_file.read())
        z_sensor_file.close()
        z_data_last = a*z_data_last+(1-a)*z_data_new
        
        x_g = x_data_last/sensitivity
        y_g = y_data_last/sensitivity
        z_g = z_data_last/sensitivity

        angle = math.degrees(math.atan((math.sqrt((x_g**2)+(y_g**2))/z_g)))
        str_angle = str(int(angle))
        sensor_data = "Horizon = %s\u00b0" % (str_angle.rjust(width))

        overlay.set_property('text', sensor_data)
        time.sleep(0.033)
        try:
            msg = bus.timed_pop(1000)
            if msg:
                if msg.type == Gst.MessageType.EOS:
                    break
        except KeyboardInterrupt:
            pipeline.send_event(Gst.Event.new_eos())

    # Free resources
    pipeline.set_state(Gst.State.NULL)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Overlay sensor data on a video')
    parser.add_argument('sensor_path', help='Sensor device to read')
    args = parser.parse_args()
    run_pipeline(args.sensor_path)
