//
//  MKMQTTServerManager.m
//  MKSmartPlug
//
//  Created by aa on 2018/6/8.
//  Copyright © 2018年 MK. All rights reserved.
//

#import "MKMQTTServerManager.h"
#import "MKMQTTServerTaskOperation.h"
#import <MQTTClient/MQTTSessionManager.h>

#ifndef moko_main_safe
#define moko_main_safe(block)\
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {\
        block();\
} else {\
        dispatch_async(dispatch_get_main_queue(), block);\
}
#endif

NSString * const MKMqttServerCustomErrorDomain = @"com.moko.MKMQTTServerSDK";

typedef NS_ENUM(NSInteger, serverCustomErrorCode){
    MKServerDisconnected = -10001,                                    //与服务器断开状态
    MKServerTopicError = -10002,                                      //发布信息的主题错误
    MKServerParamsError = -10003,                                     //输入的参数有误
    MKServerSetParamsError = -10004,                                  //设置参数出错
};

static MKMQTTServerManager *manager = nil;
static dispatch_once_t onceToken;

@interface MKMQTTServerManager()<MQTTSessionManagerDelegate>

@property (nonatomic, strong)MQTTSessionManager *sessionManager;

@property (nonatomic, assign)MKMQTTSessionManagerState managerState;

@property (nonatomic, strong)NSOperationQueue *operationQueue;

@property (nonatomic, strong)NSMutableDictionary *subscriptions;

@end

@implementation MKMQTTServerManager

+ (MKMQTTServerManager *)sharedInstance{
    dispatch_once(&onceToken, ^{
        if (!manager) {
            manager = [MKMQTTServerManager new];
        }
    });
    return manager;
}

#pragma mark - MQTTSessionManagerDelegate

- (void)sessionManager:(MQTTSessionManager *)sessionManager
     didReceiveMessage:(NSData *)data
               onTopic:(NSString *)topic
              retained:(BOOL)retained{
    if (sessionManager != self.sessionManager) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(sessionManager:didReceiveMessage:onTopic:)]) {
        moko_main_safe(^{[self.delegate sessionManager:manager didReceiveMessage:data onTopic:topic];});
    }
}

- (void)sessionManager:(MQTTSessionManager *)sessionManager didDeliverMessage:(UInt16)msgID{
    if (sessionManager != self.sessionManager) {
        return;
    }
    @synchronized(self.operationQueue) {
        NSArray *operations = [self.operationQueue.operations copy];
        for (MKMQTTServerTaskOperation *operation in operations) {
            if (operation.executing) {
                [operation sendMessageSuccess:msgID];
                break;
            }
        }
    }
}

- (void)sessionManager:(MQTTSessionManager *)sessionManager didChangeState:(MQTTSessionManagerState)newState{
    //更新当前state
    self.managerState = [self fecthSessionState:newState];
    if ([self.delegate respondsToSelector:@selector(mqttServerManagerStateChanged:)]) {
        moko_main_safe(^{[self.delegate mqttServerManagerStateChanged:self.managerState];});
    }
    NSLog(@"连接状态发生改变:---%ld",(long)newState);
    if (self.managerState == MKMQTTSessionManagerStateConnected) {
        //连接成功了，订阅主题
        self.sessionManager.subscriptions = [NSDictionary dictionaryWithDictionary:self.subscriptions];
    }
    if (self.managerState == MKMQTTSessionManagerStateError) {
        //连接出错
        [self disconnect];
    }
}

#pragma mark - public method

/**
 连接MQTT服务器
 
 @param host 服务器地址
 @param port 服务器端口
 @param tls 是否使用tls协议
 @param keepalive 心跳时间，单位秒，每隔固定时间发送心跳包, 心跳间隔不得大于120s
 @param clean session是否清除，这个需要注意，如果是false，代表保持登录，如果客户端离线了再次登录就可以接收到离线消息
 @param auth 是否使用登录验证
 @param user 用户名
 @param pass 密码
 @param clientId 客户端id，需要特别指出的是这个id需要全局唯一，因为服务端是根据这个来区分不同的客户端的，默认情况下一个id登录后，假如有另外的连接以这个id登录，上一个连接会被踢下线
 */
- (void)connectMQTTServer:(NSString *)host
                     port:(NSInteger)port
                      tls:(BOOL)tls
                keepalive:(NSInteger)keepalive
                    clean:(BOOL)clean
                     auth:(BOOL)auth
                     user:(NSString *)user
                     pass:(NSString *)pass
                 clientId:(NSString *)clientId{
    if (self.sessionManager) {
        self.sessionManager.delegate = nil;
        [self.sessionManager disconnectWithDisconnectHandler:nil];
        self.sessionManager = nil;
    }
    [self.operationQueue cancelAllOperations];
    MQTTSessionManager *sessionManager = [[MQTTSessionManager alloc] init];
    sessionManager.delegate = self;
    self.sessionManager = sessionManager;
    MQTTSSLSecurityPolicy *securityPolicy = nil;
    if (tls) {
        //需要tls
        securityPolicy = [MQTTSSLSecurityPolicy policyWithPinningMode:MQTTSSLPinningModeNone];
        securityPolicy.allowInvalidCertificates = YES;
        securityPolicy.validatesDomainName = NO;
        securityPolicy.validatesCertificateChain = NO;
    }
    [self.sessionManager connectTo:host
                              port:port
                               tls:tls
                         keepalive:keepalive
                             clean:clean
                              auth:auth
                              user:user
                              pass:pass
                              will:false
                         willTopic:nil
                           willMsg:nil
                           willQos:0
                    willRetainFlag:false
                      withClientId:clientId
                    securityPolicy:securityPolicy
                      certificates:nil
                     protocolLevel:MQTTProtocolVersion311
                    connectHandler:nil];
}

/**
 断开连接
 */
- (void)disconnect{
    [self.operationQueue cancelAllOperations];
    if (!self.sessionManager) {
        return;
    }
    self.sessionManager.delegate = nil;
    [self.sessionManager disconnectWithDisconnectHandler:nil];
    self.sessionManager = nil;
    self.managerState = MQTTSessionManagerStateStarting;
}

/**
 订阅主题,Object 为 QoS，key 为 Topic
 
 @param topicList 主题
 */
- (void)subscriptions:(NSArray <NSString *>*)topicList{
    if (!topicList
        || topicList.count == 0) {
        return;
    }
    @synchronized(self){
        for (NSString *topic in topicList) {
            if ([topic isKindOfClass:[NSString class]] && topic.length > 0) {
                [self.subscriptions setObject:@(MQTTQosLevelExactlyOnce) forKey:topic];
            }
        }
        if (self.sessionManager && self.managerState == MQTTSessionManagerStateConnected) {
            //连接成功了，订阅主题
            self.sessionManager.subscriptions = [NSDictionary dictionaryWithDictionary:self.subscriptions];
        }
    }
}

/**
 取消订阅主题
 
 @param topicList 主题列表
 */
- (void)unsubscriptions:(NSArray <NSString *>*)topicList{
    if (!self.sessionManager
        || !topicList
        || topicList.count == 0) {
        return;
    }
    @synchronized(self){
        NSMutableArray *removeTopicList = [NSMutableArray array];
        for (NSString *topic in topicList) {
            if ([topic isKindOfClass:[NSString class]] && topic.length > 0) {
                NSString *value = self.subscriptions[topic];
                if (value) {
                    [self.subscriptions removeObjectForKey:topic];
                    [removeTopicList addObject:topic];
                }
            }
        }
        if (removeTopicList.count == 0) {
            return;
        }
        self.sessionManager.subscriptions = [NSDictionary dictionaryWithDictionary:self.subscriptions];
        [self.sessionManager.session unsubscribeTopics:removeTopicList];
    }
}

- (void)sendData:(NSDictionary *)data
           topic:(NSString *)topic
        sucBlock:(void (^)(void))sucBlock
     failedBlock:(void (^)(NSError *error))failedBlock{
    if (!data || ![data isKindOfClass:[NSDictionary class]]) {
        if (failedBlock) {
            moko_main_safe(^{
                failedBlock([self getErrorWithCode:MKServerParamsError message:@"params error"]);
            })
        }
        return;
    }
    if (!topic || topic.length == 0) {
        if (failedBlock) {
            moko_main_safe(^{
                failedBlock([self getErrorWithCode:MKServerTopicError message:@"the theme of the error to publish information"]);
            })
        }
        return;
    }
    if (!self.sessionManager) {
        if (failedBlock) {
            moko_main_safe(^{
                failedBlock([self getErrorWithCode:MKServerDisconnected message:@"please connect server"]);
            })
        }
        return;
    }
    UInt16 msgid = [self.sessionManager sendData:[self dataWithJson:data] //要发送的消息体
                                           topic:topic //要往哪个topic发送消息
                                             qos:MQTTQosLevelExactlyOnce //消息级别
                                          retain:false];
    if (msgid <= 0) {
        if (failedBlock) {
            moko_main_safe(^{
                failedBlock([self getErrorWithCode:MKServerSetParamsError message:@"set data error"]);
            })
        }
        return;
    }
    MKMQTTServerTaskOperation *operation = [[MKMQTTServerTaskOperation alloc] initOperationWithID:msgid completeBlock:^(NSError *error, NSInteger operationID) {
        if (error) {
            moko_main_safe(^{
                if (failedBlock) {
                    failedBlock(error);
                }
            });
            return ;
        }
        if (msgid != operationID) {
            if (failedBlock) {
                moko_main_safe(^{
                    failedBlock([self getErrorWithCode:MKServerSetParamsError message:@"set data error"]);
                })
            }
            return;
        }
        moko_main_safe(^{
            if (sucBlock) {
                sucBlock();
            }
        });
    }];
    [self.operationQueue addOperation:operation];
}

- (NSData *)dataWithJson:(NSDictionary *)dic{
    if (!dic) {
        return nil;
    }
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    if (!jsonData) {
        return nil;
    }
    NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (!jsonString || jsonString.length == 0) {
        return nil;
    }
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    NSRange range = {0,jsonString.length};
    //去掉字符串中的空格
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    NSRange range2 = {0,mutStr.length};
    //去掉字符串中的换行符
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    return [mutStr dataUsingEncoding:NSUTF8StringEncoding];
}

- (MKMQTTSessionManagerState)fecthSessionState:(MQTTSessionManagerState)orignState{
    switch (orignState) {
        case MQTTSessionManagerStateError:
            return MKMQTTSessionManagerStateError;
        case MQTTSessionManagerStateClosed:
            return MKMQTTSessionManagerStateClosed;
        case MQTTSessionManagerStateClosing:
            return MKMQTTSessionManagerStateClosing;
        case MQTTSessionManagerStateStarting:
            return MKMQTTSessionManagerStateStarting;
        case MQTTSessionManagerStateConnected:
            return MKMQTTSessionManagerStateConnected;
        case MQTTSessionManagerStateConnecting:
            return MKMQTTSessionManagerStateConnecting;
    }
}

- (NSError *)getErrorWithCode:(serverCustomErrorCode)code message:(NSString *)message{
    NSError *error = [[NSError alloc] initWithDomain:MKMqttServerCustomErrorDomain
                                                code:code
                                            userInfo:@{@"errorInfo":(message == nil ? @"" : message)}];
    return error;
}

#pragma mark - setter & getter
- (NSOperationQueue *)operationQueue{
    if (!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
    }
    return _operationQueue;
}

- (NSMutableDictionary *)subscriptions{
    if (!_subscriptions) {
        _subscriptions = [NSMutableDictionary dictionary];
    }
    return _subscriptions;
}

@end
