// -*- Mode: Go; indent-tabs-mode: t -*-
//
// Copyright (C) 2018-2019 IOTech Ltd
//
// SPDX-License-Identifier: Apache-2.0

package driver

import (
	"encoding/json"
	"fmt"
	"net/url"
	"strings"
	"time"
	"strconv"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	sdkModel "github.com/edgexfoundry/device-sdk-go/pkg/models"
)

func startIncomingListening() error {
	var scheme = driver.Config.IncomingSchema
	var brokerUrl = driver.Config.IncomingHost
	var brokerPort = driver.Config.IncomingPort
	var username = driver.Config.IncomingUser
	var password = driver.Config.IncomingPassword
	var mqttClientId = driver.Config.IncomingClientId
	var qos = byte(driver.Config.IncomingQos)
	var keepAlive = driver.Config.IncomingKeepAlive
	var topic = driver.Config.IncomingTopic

	uri := &url.URL{
		Scheme: strings.ToLower(scheme),
		Host:   fmt.Sprintf("%s:%d", brokerUrl, brokerPort),
		User:   url.UserPassword(username, password),
	}

	var client mqtt.Client
	var err error
	for i := 1; i <= driver.Config.ConnEstablishingRetry; i++ {
		client, err = createClient(mqttClientId, uri, keepAlive)
		if err != nil && i == driver.Config.ConnEstablishingRetry {
			return err
		} else if err != nil {
			driver.Logger.Error(fmt.Sprintf("Fail to initial conn for incoming data, %v ", err))
			time.Sleep(time.Duration(driver.Config.ConnEstablishingRetry) * time.Second)
			driver.Logger.Warn("Retry to initial conn for incoming data")
			continue
		}
		break
	}

	defer func() {
		if client.IsConnected() {
			client.Disconnect(5000)
		}
	}()

	token := client.Subscribe(topic, qos, onIncomingDataReceived)
	if token.Wait() && token.Error() != nil {
		driver.Logger.Info(fmt.Sprintf("[Incoming listener] Stop incoming data listening. Cause:%v", token.Error()))
		return token.Error()
	}

	driver.Logger.Info("[Incoming listener] Start incoming data listening. ")
	select {}
}

func onIncomingDataReceived(client mqtt.Client, message mqtt.Message) {
	var data map[string]interface{}
	json.Unmarshal(message.Payload(), &data)
	
	if !checkDataWithKey(data, "name") || !checkDataWithKey(data, "subject") || !checkDataWithKey(data,"score") {
		return
	}
	
	deviceName := data["name"].(string)
	objType := data["subject"].(string)
	scoreString := data["score"].(string)
	scoreValue, _ := strconv.Atoi(scoreString)
	
	req2 := sdkModel.CommandRequest{
		DeviceResourceName: "score",
		Type:  sdkModel.Int32,
	}

	result2, err := newResult(req2, scoreValue)

	if err != nil {
		driver.Logger.Warn(fmt.Sprintf("[Incoming listener] Incoming score issue.   topic=%v msg=%v error=%v", message.Topic(), string(message.Payload()), err))
		return
	}

	req1 := sdkModel.CommandRequest{
		DeviceResourceName: "subject",
		Type: sdkModel.String,
	}

	result1, err := newResult(req1, objType)

	if err != nil {
		driver.Logger.Warn(fmt.Sprintf("[Incoming listener] Incoming subject issue.   topic=%v msg=%v error=%v", message.Topic(), string(message.Payload()), err))
		return
	}

	cvs := []*sdkModel.CommandValue{result1, result2}

	asyncValues := &sdkModel.AsyncValues{
		DeviceName:    deviceName,
		CommandValues: cvs,
	}

	driver.Logger.Info(fmt.Sprintf("[Incoming listener] Incoming reading received: topic=%v msg=%v", message.Topic(), string(message.Payload())))

	driver.AsyncCh <- asyncValues

}

func checkDataWithKey(data map[string]interface{}, key string) bool {
	val, ok := data[key]
	if !ok {
		driver.Logger.Warn(fmt.Sprintf("[Incoming listener] Incoming reading ignored. No %v found : msg=%v", key, data))
		return false
	}

	switch val.(type) {
	case string:
		return true
	default:
		driver.Logger.Warn(fmt.Sprintf("[Incoming listener] Incoming reading ignored. %v should be string : msg=%v", key, data))
		return false
	}
}
