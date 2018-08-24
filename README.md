### 1、MKSDKForDevice文件夹下面是配置智能插座的SDK

#### 1.1 如果需要配置插座的MQTT服务器信息和需要连接的WIFI信息，则首先需要让插座进入AP模式。插座上电的情况下，长按按键10S，这个时候插座黄灯快闪，表明插座进入AP模式(note:设备最多维持3分钟AP模式，配置完成之后也会退出AP模式)。从手机设置->Wi-Fi->进去选择插座AP并且连接(插座AP的SSID以MK开头)，连接成功之后，这个时候调用connectDeviceWithHost:port:connectSucBlock:connectFailedBlock:方法来连接设备.下面是完整的配置插座流程：

```
[[MKSocketManager sharedInstance] connectDeviceWithHost:@"192.168.4.1"
                                                   port:8266
                                        connectSucBlock:^(NSString *IP, NSInteger port) {
    //connect success
                                     connectFailedBlock:^(NSError *error) {
    //connect failed
 }];
```

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

```
[[MKSocketManager sharedInstance] readSmartPlugDeviceInformationWithSucBlock:^(id returnData) {
        //Read device info success
    } failedBlock:^(NSError *error) {
        //Read device info failed
    }];
```

### 2、MKSDKForMqttServer文件夹下面是配置app与mqttServer的SDK，MKMQTTServerDataNotifications.h下面的通知是SDK接收到相关数据之后抛出的通知，在需要接受数据的地方注册相应的通知可以拿到目标数据
#### 2.1 MKMQTTServerManagerDelegate
  @protocol MKMQTTServerManagerDelegate <NSObject>
//connect state delegate method
- (void)mqttServerManagerStateChanged:(MKMQTTSessionManagerState)state;
//Receives the data from the MQTT server 
- (void)sessionManager:(MKMQTTServerManager *)sessionManager didReceiveMessage:(NSData *)data onTopic:(NSString *)topic;

@end
#### 2.2APP连接MQTT服务器
在网络可用的情况下，调用[[MKMQTTServerManager sharedInstance] connectMQTTServer:port:tls:keepalive:clean:auth:user:pass:clientId:]连接自己的MQTT服务器。
#### 2.3订阅主题
插座交互主题详情请看文档。调用```- (void)subscriptions:(NSArray <NSString *>*)topicList```和```- (void)unsubscriptions:(NSArray <NSString *>*)topicList```分别进行主题的订阅和取消。
