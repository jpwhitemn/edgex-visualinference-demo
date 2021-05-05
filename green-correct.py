import time
import logging
import requests
import sys
import sched, time
import gi
gi.require_version('Gtk', '2.0')

patliteURL = "http://192.168.0.11:48082/api/v1/device/name/patlite/command/GreenLight"
patliteGreenOffBodyA = "{\"GreenLightControlState\":\"" 
patliteGreenOffBodyB = "\",\"GreenLightTimer\":\"0\"}"
headers = {'Content-type': 'application/json'}

# s = sched.scheduler(time.time, time.sleep)

# def do_something(sc): 
#     print("Doing stuff...")
#     # do your stuff
#     s.enter(60, 1, do_something, (sc,))

def send_reset_message():
    value = sys.argv[1]
    body = patliteGreenOffBodyA + value + patliteGreenOffBodyB
    try:
        requests.put(url=patliteURL, data=body, headers=headers)
    except:
        print("Cannot reset patlite yet")
    # s.enter(10,1,send_reset_message)
    # s.run()

if __name__ == "__main__":
    while True:
        send_reset_message()
        time.sleep(10)
