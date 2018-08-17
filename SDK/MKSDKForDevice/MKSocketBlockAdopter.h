//
//  MKSocketBlockAdopter.h
//  MKSmartPlug
//
//  Created by aa on 2018/6/5.
//  Copyright © 2018年 MK. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 自定义的错误码
 */
typedef NS_ENUM(NSInteger, socketCustomErrorCode){
    socketNoError = 0,                                              //永远不存在
    socketNetworkDisable = -10000,                                  //当前手机网络不可用
    socketConnectedFailed = -10001,                                 //连接外设失败
    socketDisconnected = -10002,                                    //当前外部连接的设备处于断开状态
    socketRequestDataError = -10003,                                //请求数据出错
    socketParamsError = -10004,                                     //输入的参数有误
    socketSetParamsError = -10005,                                  //设置参数出错
};

@interface MKSocketBlockAdopter : NSObject

+ (NSError *)getErrorWithCode:(socketCustomErrorCode)code message:(NSString *)message;

/**
 将第三方GCDAsyncSocket的error转换成自定义的error
 
 @param error GCDAsyncSocket的error
 @return 自定义error
 */
+ (NSError *)exchangedGCDAsyncSocketErrorToLocalError:(NSError *)error;

+ (void)operationParamsErrorBlock:(void (^)(NSError *error))block;

+ (void)operationParamsErrorWithMessage:(NSString *)message block:(void (^)(NSError *error))block;

+ (void)operationGetDataErrorBlock:(void (^)(NSError *error))block;

+ (void)operationDisConnectedErrorBlock:(void (^)(NSError *error))block;

+ (void)operationDataErrorWithReturnData:(NSDictionary *)returnData block:(void (^)(NSError *error))block;

+ (void)operationConnectTimeoutBlock:(void (^)(NSError *error))block;

@end
