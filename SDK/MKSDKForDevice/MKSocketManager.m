//
//  MKSocketManager.m
//  MKSmartPlug
//
//  Created by aa on 2018/6/5.
//  Copyright © 2018年 MK. All rights reserved.
//

#import "MKSocketManager.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "MKSocketBlockAdopter.h"
#import "MKSocketAdopter.h"
#import "MKSocketTaskOperation.h"

//设备默认的ip地址
NSString *const defaultHostIpAddress = @"192.168.4.1";
//设备默认的端口号
NSInteger const defaultPort = 8266;

static NSTimeInterval const defaultConnectTime = 15.f;
static NSTimeInterval const defaultCommandTime = 2.f;

@interface MKSocketManager()<GCDAsyncSocketDelegate>

@property (nonatomic, strong)GCDAsyncSocket *socket;

@property (nonatomic, strong)dispatch_queue_t socketQueue;

@property (nonatomic, strong)NSOperationQueue *operationQueue;

@property (nonatomic, copy)void (^connectSucBlock)(NSString *IP, NSInteger port);

@property (nonatomic, copy)void (^connectFailedBlock)(NSError *error);

/**
 连接定时器，超过指定时间将会视为连接失败
 */
@property (nonatomic, strong)dispatch_source_t connectTimer;

/**
 连接超时标记
 */
@property (nonatomic, assign)BOOL connectTimeout;

@end

@implementation MKSocketManager

#pragma mark - life circle

+ (MKSocketManager *)sharedInstance{
    static MKSocketManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!manager) {
            manager = [self socketManager];
        }
    });
    return manager;
}

+ (MKSocketManager *)socketManager{
    return [[self alloc] init];
}

- (instancetype)init{
    if (self = [super init]) {
        _socketQueue = dispatch_queue_create("com.moko.MKSocketManagerQueue", nil);
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
    }
    return self;
}

#pragma mark - delegate

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    if (!sock || self.connectTimeout) {
        return;
    }
    [self.operationQueue cancelAllOperations];
    self.connectTimeout = NO;
    if (self.connectTimer) {
        dispatch_cancel(self.connectTimer);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.connectSucBlock) {
            self.connectSucBlock(sock.connectedHost, sock.connectedPort);
        }
    });
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err{
    if (!err) {
        return;
    }
    self.connectTimeout = NO;
    if (self.connectTimer) {
        dispatch_cancel(self.connectTimer);
    }
    [self.operationQueue cancelAllOperations];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.connectFailedBlock) {
            self.connectFailedBlock([MKSocketBlockAdopter exchangedGCDAsyncSocketErrorToLocalError:err]);
        }
    });
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    //发送成功之后读取数值
    NSLog(@"发送数据成功");
    [self.socket readDataWithTimeout:defaultCommandTime tag:tag];
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length{
    @synchronized(self.operationQueue) {
        NSArray *operations = [self.operationQueue.operations copy];
        for (MKSocketTaskOperation *operation in operations) {
            if (operation.executing) {
                [operation sendDataToPlugSuccess:NO operationID:tag returnData:nil];
                break;
            }
        }
    }
    return 0.f;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSLog(@"socket:%p didReadData:withTag:%ld", sock, tag);
    NSString *httpResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"HTTP Response:\n%@", httpResponse);
    @synchronized(self.operationQueue) {
        NSArray *operations = [self.operationQueue.operations copy];
        for (MKSocketTaskOperation *operation in operations) {
            if (operation.executing) {
                [operation sendDataToPlugSuccess:YES
                                     operationID:tag
                                      returnData:[MKSocketAdopter dictionaryWithJsonString:httpResponse]];
                break;
            }
        }
    }
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length{
    @synchronized(self.operationQueue) {
        NSArray *operations = [self.operationQueue.operations copy];
        for (MKSocketTaskOperation *operation in operations) {
            if (operation.executing) {
                [operation sendDataToPlugSuccess:NO operationID:tag returnData:nil];
                break;
            }
        }
    }
    return 0.f;
}

#pragma mark - public method

/**
 连接plug设备

 @param host host ip address
 @param port port (0~65535)
 @param sucBlock 连接成功回调
 @param failedBlock 连接失败回调
 */
- (void)connectDeviceWithHost:(NSString *)host
                         port:(NSInteger)port
              connectSucBlock:(void (^)(NSString *IP, NSInteger port))sucBlock
           connectFailedBlock:(void (^)(NSError *error))failedBlock{
    if (![MKSocketAdopter isValidatIP:host] || port < 0 || port > 65535) {
        [MKSocketBlockAdopter operationParamsErrorBlock:failedBlock];
        return;
    }
    __weak __typeof(&*self)weakSelf = self;
    [self connectHost:host port:port sucBlock:^(NSString *IP, NSInteger port) {
        if (sucBlock) {
            sucBlock(IP,port);
        }
        __strong typeof(self) sself = weakSelf;
        [sself clearConnectBlock];
    } failedBlock:^(NSError *error) {
        if (failedBlock) {
            failedBlock(error);
        }
        __strong typeof(self) sself = weakSelf;
        [sself clearConnectBlock];
    }];
}

/**
 断开连接
 */
- (void)disconnect{
    [self.socket disconnect];
}

#pragma mark - interface
/**
 读取设备信息

 @param sucBlock 成功回调
 @param failedBlock 失败回调
 */
- (void)readSmartPlugDeviceInformationWithSucBlock:(void (^)(id returnData))sucBlock
                                       failedBlock:(void (^)(NSError *error))failedBlock{
    NSString *jsonString = [MKSocketAdopter convertToJsonData:@{@"header":@(4001)}];
    [self addTaskWithTaskID:socketReadDeviceInformationOperation
                 jsonString:jsonString
                   sucBlock:sucBlock
                failedBlock:failedBlock];
}

/**
 设置给插座的mqtt服务器信息。插座接收到此信息，并成功解析，待插座成功连接wifi网络后，插座会自动去连接手机指定的mqtt服务器

 @param host mqtt服务器主机host
 @param port mqtt服务器主机端口号，范围0~65535
 @param mode 连接方式 0：tcp,1:ssl
 @param qos mqqt服务质量
 @param keepalive plug跟mqtt服务器连接之后心跳包发送间隔，60~120，单位：s
 @param clean NO:表示创建一个持久会话，在客户端断开连接时，会话仍然保持并保存离线消息，直到会话超时注销。YES:表示创建一个新的临时会话，在客户端断开时，会话自动销毁。
 @param clientId plug作为客户端的id,mqtt服务器使用该id来区分不同的plug设备,如果该项为空，则plug默认会用mac地址作为clientID跟mqtt服务器通信。建议使用设备mac地址。长度0~32
 @param username plug连接mqtt服务器时候的用户名,长度1~32
 @param password plug连接mqtt服务器时候的密码,长度1~32
 @param sucBlock 成功回调
 @param failedBlock 失败回调
 */
- (void)configMQTTServerHost:(NSString *)host
                        port:(NSInteger)port
                 connectMode:(mqttServerConnectMode)mode
                         qos:(mqttServerQosMode)qos
                   keepalive:(NSInteger)keepalive
                cleanSession:(BOOL)clean
                    clientId:(NSString *)clientId
                    username:(NSString *)username
                    password:(NSString *)password
                    sucBlock:(void (^)(id returnData))sucBlock
                 failedBlock:(void (^)(NSError *error))failedBlock{
    if (![MKSocketAdopter isValidatIP:host] && ![MKSocketAdopter isDomainName:host]) {
        [MKSocketBlockAdopter operationParamsErrorWithMessage:@"Host error" block:failedBlock];
        return;
    }
    if (port < 0 || port > 65535) {
        [MKSocketBlockAdopter operationParamsErrorWithMessage:@"Port effective range : 0~65535" block:failedBlock];
        return;
    }
    if (keepalive < 60 || keepalive > 120) {
        [MKSocketBlockAdopter operationParamsErrorWithMessage:@"Keep alive effective range : 0~65535" block:failedBlock];
        return;
    }
    if (clientId && clientId.length > 32) {
        [MKSocketBlockAdopter operationParamsErrorWithMessage:@"Client id error" block:failedBlock];
        return;
    }
    if (!username || username.length > 32) {
        [MKSocketBlockAdopter operationParamsErrorWithMessage:@"User name error" block:failedBlock];
        return;
    }
    if (!password || password.length > 32) {
        [MKSocketBlockAdopter operationParamsErrorWithMessage:@"Password error" block:failedBlock];
        return;
    }
    NSInteger connectMode = (mode == mqttServerConnectTCPMode ? 0 : 1);
    NSInteger qosNumber = 2;
    if (qos == mqttQosLevelAtMostOnce) {
        qosNumber = 0;
    }else if (qos == mqttQosLevelAtLeastOnce){
        qosNumber = 1;
    }
    NSDictionary *commandDic = @{
                                 @"header":@(4002),
                                 @"host":host,
                                 @"port":@(port),
                                 @"clientId":(clientId ? clientId : @""),
                                 @"connect_mode":@(connectMode),
                                 @"username":username,
                                 @"password":password,
                                 @"keepalive":@(keepalive),
                                 @"qos":@(qosNumber),
                                 @"clean_session":(clean ? @(1) : @(0)),
                                 };
    NSString *jsonString = [MKSocketAdopter convertToJsonData:commandDic];
    [self addTaskWithTaskID:socketConfigMQTTServerOperation
                 jsonString:jsonString
                   sucBlock:sucBlock
                failedBlock:failedBlock];
}

/**
 手机给插座指定连接特定ssid的WiFi网络。注意:调用该方法的时候，应该确保已经把mqtt服务器信息设置给plug了，否则调用该方法会出现错误

 @param ssid wifi ssid
 @param password wifi密码,不需要密码的wifi网络，密码可以不填
 @param security wifi加密策略
 @param sucBlock 成功回调
 @param failedBlock 失败回调
 */
- (void)configWifiSSID:(NSString *)ssid
              password:(NSString *)password
              security:(wifiSecurity)security
              sucBlock:(void (^)(id returnData))sucBlock
           failedBlock:(void (^)(NSError *error))failedBlock{
    if (!ssid || ssid.length == 0) {
        [MKSocketBlockAdopter operationParamsErrorWithMessage:@"SSID error" block:failedBlock];
        return;
    }
    NSInteger wifi_security = 0;
    if (security == wifiSecurity_WEP) {
        wifi_security = 1;
    }else if (security == wifiSecurity_WPA_PSK){
        wifi_security = 2;
    }else if (security == wifiSecurity_WPA2_PSK){
        wifi_security = 3;
    }else if (security == wifiSecurity_WPA_WPA2_PSK){
        wifi_security = 4;
    }
    NSDictionary *commandDic = @{
                                 @"header":@(4003),
                                 @"wifi_ssid":ssid,
                                 @"wifi_pwd":((!password || password.length == 0) ? @"" : password),
                                 @"wifi_security":@(wifi_security),
                                 };
    NSString *jsonString = [MKSocketAdopter convertToJsonData:commandDic];
    [self addTaskWithTaskID:socketConfigWifiOperation
                 jsonString:jsonString
                   sucBlock:sucBlock
                failedBlock:failedBlock];
}

#pragma mark - connect private method
- (void)connectHost:(NSString *)host
               port:(NSInteger)port
           sucBlock:(void (^)(NSString *IP, NSInteger port))sucBlock
        failedBlock:(void (^)(NSError *error))failedBlock{
    self.connectSucBlock = nil;
    self.connectSucBlock = sucBlock;
    self.connectFailedBlock = nil;
    self.connectFailedBlock = failedBlock;
    if (self.socket.isConnected) {
        [self.socket disconnect];
    }
    self.connectTimeout = NO;
    if (self.connectTimer) {
        dispatch_cancel(self.connectTimer);
    }
    [self initConnectTimer];
    NSError *error = nil;
    BOOL pass = [self.socket connectToHost:host onPort:port withTimeout:defaultConnectTime error:&error];
    if (!pass) {
        [self.operationQueue cancelAllOperations];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failedBlock) {
                failedBlock(error);
            }
        });
    }
}

- (void)addTaskWithTaskID:(MKSocketOperationID)taskID
               jsonString:(NSString *)jsonString
                 sucBlock:(void (^)(id returnData))sucBlock
              failedBlock:(void (^)(NSError *error))failedBlock{
    if (!jsonString) {
        [MKSocketBlockAdopter operationGetDataErrorBlock:failedBlock];
        return;
    }
    if (!self.socket.isConnected) {
        [MKSocketBlockAdopter operationDisConnectedErrorBlock:failedBlock];
        return;
    }
    MKSocketTaskOperation *operation = [[MKSocketTaskOperation alloc] initOperationWithID:taskID completeBlock:^(NSError *error, MKSocketOperationID operationID, id returnData) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failedBlock) {
                    failedBlock(error);
                }
            });
            return ;
        }
        if (!returnData || ![returnData isKindOfClass:[NSDictionary class]]) {
            //出错
            [MKSocketBlockAdopter operationGetDataErrorBlock:failedBlock];
        }
        if ([returnData[@"code"] integerValue] != 0) {
            //数据错误
            [MKSocketBlockAdopter operationDataErrorWithReturnData:returnData block:failedBlock];
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (sucBlock) {
                sucBlock(returnData);
            }
        });
    }];
    [self.operationQueue addOperation:operation];
    NSData *commandData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:commandData withTimeout:defaultCommandTime tag:taskID];
}

- (void)clearConnectBlock{
    if (self.connectSucBlock) {
        self.connectSucBlock = nil;
    }
    if (self.connectFailedBlock) {
        self.connectFailedBlock = nil;
    }
}

- (void)initConnectTimer{
    dispatch_queue_t connectQueue = dispatch_queue_create("connectSmartPlugQueue", DISPATCH_QUEUE_CONCURRENT);
    self.connectTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,connectQueue);
    //开始时间
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, defaultConnectTime * NSEC_PER_SEC);
    //间隔时间
    uint64_t interval = defaultConnectTime * NSEC_PER_SEC;
    dispatch_source_set_timer(self.connectTimer, start, interval, 0);
    __weak __typeof(&*self)weakSelf = self;
    dispatch_source_set_event_handler(self.connectTimer, ^{
        __strong typeof(self) sself = weakSelf;
        sself.connectTimeout = YES;
        dispatch_cancel(sself.connectTimer);
        [sself.socket disconnect];
        [MKSocketBlockAdopter operationConnectTimeoutBlock:sself.connectFailedBlock];
    });
    dispatch_resume(self.connectTimer);
}



#pragma mark - setter & getter
- (NSOperationQueue *)operationQueue{
    if (!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
    }
    return _operationQueue;
}

@end
