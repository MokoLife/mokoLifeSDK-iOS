//
//  MKMQTTServerBlockAdopter.h
//  MKSmartPlug
//
//  Created by aa on 2018/6/22.
//  Copyright © 2018年 MK. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 自定义的错误码
 */
typedef NS_ENUM(NSInteger, serverCustomErrorCode){
    serverDisconnected = -10001,                                    //与服务器断开状态
    serverTopicError = -10002,                                      //发布信息的主题错误
    serverParamsError = -10003,                                     //输入的参数有误
    serverSetParamsError = -10004,                                  //设置参数出错
};

@interface MKMQTTServerBlockAdopter : NSObject

+ (NSError *)getErrorWithCode:(serverCustomErrorCode)code message:(NSString *)message;

+ (void)operationDisConnectedErrorBlock:(void (^)(NSError *error))block;

+ (void)operationTopicErrorBlock:(void (^)(NSError *error))block;

+ (void)operationSetDataErrorBlock:(void (^)(NSError *error))block;

+ (void)operationParamsErrorBlock:(void (^)(NSError *error))block;

@end
