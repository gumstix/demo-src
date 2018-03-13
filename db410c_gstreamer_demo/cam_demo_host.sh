#!/bin/bash

echo "Waiting for UDP stream from Dragonboard..."
mode=0
while getopts m: option
do
  case "${option}"
    in
      m) mode=1;;
  esac
done

if [ $mode -eq 0 ]; then
  udp_port=0
  while [ $udp_port -eq 0 ] 
  do
    received_count=$(sudo timeout 1 tcpdump port 4000 2>&1 | grep 'received by filter' | awk '{print $1;}')
    echo $received_count
    if [ $received_count -gt 10 ]; then
      udp_port=4000
      break
    fi
    received_count=$(sudo timeout 1 tcpdump port 5000 2>&1 | grep 'received by filter' | awk '{print $1;}')
    echo $received_count
    if [ $received_count -gt 10 ]; then
      udp_port=5000
      break
    fi
    received_count=$(sudo timeout 1 tcpdump port 6000 2>&1 | grep 'received by filter' | awk '{print $1;}')
    echo $received_count
    if [ $received_count -gt 10 ]; then
      udp_port=6000
      break
    fi
  done
  echo $udp_port
  gst-launch-1.0 udpsrc port=${udp_port} ! application/x-rtp,encoding-name=H264,payload=96 ! rtph264depay ! h264parse ! avdec_h264 ! autovideosink
else
#  gst-launch-1.0 udpsrc port=4000 ! application/x-rtp,encoding-name=H264,payload=96 ! rtph264depay ! h264parse ! avdec_h264 ! autovideosink & \
#  gst-launch-1.0 udpsrc port=5000 ! application/x-rtp,encoding-name=H264,payload=96 ! rtph264depay ! h264parse ! avdec_h264 ! autovideosink
  echo ok
fi