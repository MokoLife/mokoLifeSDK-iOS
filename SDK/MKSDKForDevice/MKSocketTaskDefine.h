
/*
 命令ID
 */
typedef NS_ENUM(NSInteger, MKSocketOperationID){
    socketUnknowOperation = 0,                           //初始状态
    socketReadDeviceInformationOperation = 1,            //读取设备信息
    socketConfigMQTTServerOperation = 2,                 //配置mqtt服务器信息
    socketConfigWifiOperation = 3,                       //配置plug要连接的wifi
};

@protocol MKSocketOperationProtocol <NSObject>

- (void)sendDataToPlugSuccess:(BOOL)success operationID:(MKSocketOperationID)operationID returnData:(NSDictionary *)returnData;

@end

