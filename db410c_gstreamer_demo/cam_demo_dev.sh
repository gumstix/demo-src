#!/bin/bash
function udp_stream {
  echo -e "host:\n\tgst-launch-1.0 udpsrc ${port} ! application/x-rtp,encoding-name=H264,payload=96 ! rtph264depay ! h264parse ! avdec_h264 ! autovideosink"
case "${camera}"
  in
  1)  gst-launch-1.0 -v -e v4l2src device=/dev/video0 ! 'video/x-raw,format=UYVY,width=640,height=480,n-threads=2' ! videoflip method=counterclockwise ! videoconvert ! $videoencoder ! h264parse ! rtph264pay ! udpsink host="$ip_addr" "$port"; ;;
  2)  gst-launch-1.0 -v -e v4l2src device=/dev/video1 ! 'video/x-raw,format=UYVY,width=640,height=480,n-threads=2' ! videoflip method=rotate-180 ! videoconvert ! $videoencoder ! h264parse ! rtph264pay ! udpsink host="$ip_addr" "$port"; ;;
  3)  gst-launch-1.0 -v -e v4l2src device=/dev/video0 ! 'video/x-raw,format=UYVY,width=640,height=480,framerate=10/1' ! textoverlay text='CAM0' halignment=left valignment=top font-desc='Sans Italic 24' ! videomixer name=mix sink_1::xpos=0 sink_1::ypos=480 sink_1::zorder=3 ! videoconvert ! $videoencoder ! h264parse ! rtph264pay ! udpsink host="$ip_addr" "$port" v4l2src device=/dev/video1 ! 'video/x-raw,format=UYVY,width=640,height=480,framerate=10/1' ! videoflip method=rotate-180 ! textoverlay text='CAM1' halignment=left valignment=top font-desc='Sans Italic 24' ! mix.; ;;
  *) echo "Invalid camera option";;
esac
}

function hdmi_stream {
  case "${camera}"
  in
  1)       
      gst-launch-1.0 -v -e v4l2src device=/dev/video0 ! 'video/x-raw,format=UYVY,width=1920,height=1080,framerate=10/1' ! videoflip method=counterclockwise ! glimagesink; ;;
  2)
      gst-launch-1.0 -v -e v4l2src device=/dev/video1 ! 'video/x-raw,format=UYVY,width=1920,height=1080,framerate=10/1' ! videoflip method=rotate-180 ! glimagesink; ;;
  3)
      gst-launch-1.0 -v -e v4l2src device=/dev/video0 ! 'video/x-raw,format=UYVY,width=1280,height=720,framerate=10/1' ! textoverlay text='CAM0' halignment=left valignment=top font-desc='Sans Italic 24' ! glvideomixer name=mix sink_1::xpos=0 sink_1::ypos=640 sink_0::zorder=0 sink_1::zorder=1 ! glimagesink v4l2src device=/dev/video1 ! 'video/x-raw,format=UYVY,width=1280,height=720,framerate=10/1' ! videoflip method=rotate-180 ! textoverlay text='CAM1' halignment=left valignment=top font-desc='Sans Italic 24' ! mix.; ;;
  *) echo "Invalid camera option";;
esac
} 



videoencoder=`gst-inspect-1.0 --plugin | grep h264enc | awk '{print $2}'`
videoencoder=${videoencoder%?};

# Reset all entity camera links
echo "Resetting pipeline..."
media-ctl -r -d /dev/media1
# Connect CSI0 to ISP0 to RDI0
media-ctl -d /dev/media1 -l '"msm_csiphy0":1->"msm_csid0":0[1],"msm_csid0":1->"msm_ispif0":0[1],"msm_ispif0":1->"msm_vfe0_rdi0":0[1]'
# Connect CSI1 to ISP1 to RDI1
media-ctl -d /dev/media1 -l '"msm_csiphy1":1->"msm_csid1":0[1],"msm_csid1":1->"msm_ispif1":0[1],"msm_ispif1":1->"msm_vfe0_rdi1":0[1]'
echo "Done reset"

while getopts i:c: option
do
  case "${option}"
    in
      i) ip_addr=${OPTARG};;
      c) camera=${OPTARG};;
  esac
done

case "${camera}"
  in
  1) 
      port="port=4000";;
  2)
      port="port=5000";;
  3)
      port="port=6000";;
esac

if ! [[ $ip_addr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
  if [ $camera -eq 3 ]; then
    resolution="UYVY2X8/1280x720"
  else
    resolution="UYVY2X8/1920x1080"
  fi
  echo $resolution
  cam1_formats='"ov5640 1-0074":0[fmt:'"$resolution"' field:none],"msm_csiphy1":0[fmt:'"$resolution"' field:none],"msm_csid1":0[fmt:'"$resolution"' field:none],"msm_ispif1":0[fmt:'"$resolution"' field:none],"msm_vfe0_rdi1":0[fmt:'"$resolution"' field:none]'
  cam0_formats='"ov5640 1-0076":0[fmt:'"$resolution"' field:none],"msm_csiphy0":0[fmt:'"$resolution"' field:none],"msm_csid0":0[fmt:'"$resolution"' field:none],"msm_ispif0":0[fmt:'"$resolution"' field:none],"msm_vfe0_rdi0":0[fmt:'"$resolution"' field:none]'
  echo $cam0_formats
  echo "Not a valid IP address.  Streaming to display"
  env_string="DISPLAY=:0"
  media-ctl -d /dev/media1 -V "$cam0_formats,$cam1_formats"
  hdmi_stream
else
  resolution="UYVY2X8/640x480"
  cam1_formats='"ov5640 1-0074":0[fmt:'"$resolution"' field:none],"msm_csiphy1":0[fmt:'"$resolution"' field:none],"msm_csid1":0[fmt:'"$resolution"' field:none],"msm_ispif1":0[fmt:'"$resolution"' field:none],"msm_vfe0_rdi1":0[fmt:'"$resolution"' field:none]'
  cam0_formats='"ov5640 1-0076":0[fmt:'"$resolution"' field:none],"msm_csiphy0":0[fmt:'"$resolution"' field:none],"msm_csid0":0[fmt:'"$resolution"' field:none],"msm_ispif0":0[fmt:'"$resolution"' field:none],"msm_vfe0_rdi0":0[fmt:'"$resolution"' field:none]'
  echo $cam0_formats
  echo "Host IP address: ${ip_addr}"
  env_string=""
  media-ctl -d /dev/media1 -V "$cam0_formats,$cam1_formats"
  udp_stream
fi


