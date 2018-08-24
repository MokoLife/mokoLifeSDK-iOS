### 1. Below the MKSDKForDevice folder is the SDK to configure the smart plug

#### 1.1 If you want configure the MQTT sever information and the wifi information to connect for smart plug,you need make the smart plug into AP mode(Please refer to the MokoLife user manual):plug the smart plug into power socket,press the button for 10 seconds till the smart plug indicator blink amber light which indicate the smart plug into AP mode(Note:The timeout period for AP mode is 3 minutes,once you have configured the information to the smart plug,it will end AP mode).Enter the Wlan page and select the smart plug hotspot to connect ,when connect successfully,call connectDeviceWithHost:port:connectSucBlock:connectFailedBlock methods to connect smart plug.Following is the complete configuration of the smart plug process: 

##### step1
```
[[MKSocketManager sharedInstance] connectDeviceWithHost:@"192.168.4.1"
                                                   port:8266
                                        connectSucBlock:^(NSString *IP, NSInteger port) {
    //connect success
                                     connectFailedBlock:^(NSError *error) {
    //connect failed
 }];
```
##### step2

```
[[MKSocketManager sharedInstance] readSmartPlugDeviceInformationWithSucBlock:^(id returnData) {
        //Read device info success
    } failedBlock:^(NSError *error) {
        //Read device info failed
    }];
```
##### step3

```
[[MKSocketManager sharedInstance] configMQTTServerHost:@"your MQTT Server host"
                                                      port:port
                                               connectMode:mqttServerConnectTCPMode
                                                       qos:mqttQosLevelExactlyOnce
                                                 keepalive:60
                                              cleanSession:YES
                                              clientId:@"your device mac address"
                                              username:@"your MQTT Server userName" 
                                              password:@"your MQTT Server password"
                                                  sucBlock:^(id returnData) {
        //Config Success
    }
                                               failedBlock:^(NSError *error) {
        //Config Failed
    }];
```
##### step4

```
[[MKSocketManager sharedInstance] configWifiSSID:your wifi ssid
                                        password:wifi password
                                        security:wifiSecurity_WPA2_PSK
                                        sucBlock:^(id returnData) {
        //Config Success
    } failedBlock:^(NSError *error) {
        //Config Failed
    }];
```

### 2. The MKSDKForMqttServer folder is the SDK that configures the APP and MQTTServer

#### 2.1 MKMQTTServerManagerDelegate
  @protocol MKMQTTServerManagerDelegate <NSObject>

- (void)mqttServerManagerStateChanged:(MKMQTTSessionManagerState)state;//connect state delegate method

- (void)sessionManager:(MKMQTTServerManager *)sessionManager didReceiveMessage:(NSData *)data onTopic:(NSString *)topic;//Receives the data from the MQTT server 

@end

#### 2.2 APP connect to the MQTT server
When the network is available,call [[MKMQTTServerManager sharedInstance] connectMQTTServer:port:tls:keepalive:clean:auth:user:pass:clientId:] to connect your MQTT server.

#### 2.3 Subscribe topic
Please refer to the MQTT protocal document for the topic of the smart plug.Call ```- (void)subscriptions:(NSArray <NSString *>*)topicList``` and ```- (void)unsubscriptions:(NSArray <NSString *>*)topicList``` to subscribe and unsubscribe the topic separatrly.

#### 2.4 APP publish data to a specified topic
Please refer to the MQTT protocal document for the topic of the smart plug.
```- (void)sendData:(NSDictionary *)data topic:(NSString *)topic sucBlock:(void (^)(void))sucBlock failedBlock:(void (^)(NSError *error))failedBlock```
