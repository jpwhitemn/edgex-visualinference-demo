#!/bin/bash
echo "stopping redis"
sudo /etc/init.d/redis-server stop
echo "stopping mosquitto"
sudo systemctl stop mosquitto.service
echo "starting EdgeX"
docker-compose up -d
echo "starting the SNMP device service"
if ! pgrep -x "device-snmp-go" > /dev/null
then
    cd ./device-snmp-go/cmd
    ./device-snmp-go > /dev/null 2>&1 &
    cd ../..
else
    echo "SNMP device service already running - skipping start"
fi
echo "starting the MQTT device service"
if ! pgrep -x "device-mqtt" > /dev/null
then
    cd ./device-mqtt-go/cmd
    ./device-mqtt > /dev/null 2>&1 &
    cd ../..
else
    echo "MQTT device service already running - skipping start"
fi
# echo "starting the REST device service"
# if ! pgrep -x "device-rest-go" > /dev/null
# then
#     cd ./device-rest-go/cmd
#     ./device-rest-go > /dev/null 2>&1 &
#     cd ../..
# else
#     echo "REST device service already running - skipping start"
# fi
echo "start the camera"
if ! pgrep -x "gst-launch-1.0" > /dev/null
then
    gst-launch-1.0 v4l2src device="/dev/video0" ! videoconvert !  jpegenc ! rtpjpegpay ! udpsink  host=localhost port=5000 > /dev/null 2>&1 &
else   
    echo "Camera already streaming"
fi
echo "start visual inference"
if ! pgrep -f "python3 objectdetect.py" > /dev/null
then
    python3 objectdetect.py > /dev/null 2>&1 &
else
    echo "visual inference already running"
fi
# echo "starting patlite reset"
# if ! pgrep -f "python3 green-correct.py" > /dev/null
# then
#     python3 green-correct.py 1 > /dev/null 2>&1 &
# else
#     echo "Patlite correction already running"
# fi
./create-rules.sh
echo "done"
