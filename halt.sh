#!/bin/bash
echo "stopping the patlite reset"
GRNPID=`pgrep -f "green-correct.py"`
if [ "$GRNPID" == "" ]; then
    echo " patlite reset not running"
else
    kill -9 GRNPID
fi
echo "stopping the visual inference"
VIPID=`pgrep -f "python3 objectdetect.py"`
if [ "$VIPID" == "" ]; then
    echo " visual inference not running"
else
    kill -9 $VIPID
fi
echo "stopping the camera stream"
GSTPID=`pgrep -f "gst-launch-1.0"`
if [ "$GSTPID" == "" ]; then
    echo " camera stream not running"
else
    killall gst-launch-1.0
fi
echo "stopping the MQTT device service"
MQTTDSPID=`pgrep -x "device-mqtt"`
if [ "$MQTTDSPID" == "" ]; then
    echo " MQTT device service not running"
else
    killall device-mqtt
fi
echo "stopping the SNMP device service"
SNMPPID=`pgrep -x "device-snmp-go"`
if [ "$SNMPPID" == "" ]; then
    echo " SNMP device service not running"
else
    killall device-snmp-go
fi
echo "stopping EdgeX"
docker-compose down
if [ -z "$1" ]
then
    echo "No Docker volume cleanup specified (use clean arg to specify)"
else
    if [ "$1" = "clean" ]; then
        echo "Cleaning Docker volumes"
        docker volume prune -f
    fi
fi
echo "done"

