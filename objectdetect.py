import time
import logging
import paho.mqtt.client as paho
import requests
import json
import gi
gi.require_version('Gtk', '2.0')
import gluoncv as gcv
from gluoncv.utils import try_import_cv2
cv2 = try_import_cv2()
import mxnet as mx

def edgex_send_function(class_IDs, scores):
    for i in range(len(scores[0])):
        cid = int(class_IDs[0][i].asnumpy())
        cname = net.classes[cid]
        score = float(scores[0][i].asnumpy())
        if score > 0.9:
            logging.info("%s:%s", cname, score)
            send_mqtt_message(cname,score)
            #send_rest_message(cname,score)

def send_rest_message(cname, score):
    URL = "http://localhost:49986/api/v1/resource/visualinference"
    headers = {'Content-type': 'application/json'}
    msg = {"name":"vi-device","subject": cname, "score":str(int(score * 100))}
    #print (msg)
    j = json.dumps(msg)
    requests.post(url=URL, data=j, headers=headers)

def send_mqtt_message(cname, score):
    # TODO param this info to config
    topic = "DataTopic"
    msg = {"name":"vi-device","subject": cname, "score": str(int(score * 100))}
    #print (msg)
    j = json.dumps(msg)
    pubClient.publish(topic, j)

def on_disconnect(client, userdata, rc):
    if rc != 0:
        logging.error("Unexpected MQTT disconnection.")

def init_function():
    logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.INFO)
    global model_name
    global net
    # Load the model
    # TODO make model a command line arg
    model_name = 'ssd_512_mobilenet1.0_voc'
    # download and load the pre-trained model
    net = gcv.model_zoo.get_model(model_name, pretrained=True)
    # Compile the model for faster speed
    net.hybridize()

def init_mqtt():
    global pubClient
    # TODO param this info to config
    pubClient = paho.Client("camera_1")
    broker = "localhost"
    port = 1883
    pubClient.connect(broker, port)  
    pubClient.on_disconnect = on_disconnect  

def load_camera():
    # Load the webcam handler

    #print(cv2.getBuildInformation())  -- for debugging
    #cap = cv2.VideoCapture(1)
    #cap = cv2.VideoCapture("v4l2src device=/dev/video1 ! videoconvert ! appsink", cv2.CAP_GSTREAMER);
    # TODO make camera URI a command line arg
    global cap
    cap = cv2.VideoCapture("udpsrc uri=udp://localhost:5000 ! application/x-rtp,encoding-name=jpeg,payload=26 ! rtpjpegdepay ! jpegdec ! videoconvert ! appsink");
    time.sleep(1) ### letting the camera autofocus

def detect_objects():
    while (cap.isOpened()):
        try: 
            # Load frame from the camera
            ret, frame = cap.read()

            if ret==True:

                # Image pre-processing
                frame = mx.nd.array(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)).astype('uint8')
                rgb_nd, frame = gcv.data.transforms.presets.ssd.transform_test(frame, short=512, max_size=1400)

                # Run frame through network
                class_IDs, scores, bounding_boxes = net(rgb_nd)

                # send results to EdgeX
                edgex_send_function(class_IDs,scores)
                
                # Display the result
                img = gcv.utils.viz.cv_plot_bbox(frame, bounding_boxes[0], scores[0], class_IDs[0], class_names=net.classes)
                gcv.utils.viz.cv_plot_image(img)
                cv2.waitKey(1)
            else:
                logging.error("No frame read")
                break

        except KeyboardInterrupt:
            logging.warning("Terminating")
            cap.release()
            cv2.destroyAllWindows()    

if __name__ == "__main__":
    init_function()
    init_mqtt()
    load_camera()
    detect_objects()
    logging.info("Exiting")


