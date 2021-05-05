#!/bin/bash
echo "creating command rules"
echo "  adding stream"
# curl --header "Content-Type: application/json" --request POST --data '{"sql": "create stream watch1() WITH (FORMAT=\"JSON\", TYPE=\"edgex\")"}' http://localhost:48075/streams
curl --header "Content-Type: application/json" --request POST --data '{"sql": "create stream watch2() WITH (FORMAT=\"JSON\", TYPE=\"edgex\")"}' http://localhost:48075/streams
echo "creating rules"
# echo "  adding person rule"
# curl --header "Content-Type: application/json" --request POST --data '{"id": "vi-device", "sql": "SELECT subject FROM watch1 WHERE subject = \"person\"", "actions": [{"rest": {"url": "http://192.168.0.11:48082/api/v1/device/name/patlite/command/GreenLight","method": "put","retryInterval": -1,"dataTemplate": "{\"GreenLightControlState\":\"2\",\"GreenLightTimer\":\"0\"}","sendSingle": true}},{"log":{}}]}' http://localhost:48075/rules
echo "  adding dog rule"
curl --header "Content-Type: application/json" --request POST --data '{"id": "vi-device2", "sql": "SELECT subject FROM watch2 WHERE subject = \"dog\"", "actions": [{"rest": {"url": "http://192.168.0.11:48082/api/v1/device/name/patlite/command/GreenLight","method": "put","retryInterval": -1,"dataTemplate": "{\"GreenLightControlState\":\"2\",\"GreenLightTimer\":\"0\"}","sendSingle": true}},{"log":{}}]}' http://localhost:48075/rules
echo "done creating rules"
