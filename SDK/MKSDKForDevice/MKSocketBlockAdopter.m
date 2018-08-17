//
//  MKSocketBlockAdopter.m
//  MKSmartPlug
//
//  Created by aa on 2018/6/5.
//  Copyright © 2018年 MK. All rights reserved.
//

#import "MKSocketBlockAdopter.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>

NSString * const socketCustomErrorDomain = @"com.moko.MKPlugDeviceSDK";

@implementation MKSocketBlockAdopter

+ (NSError *)getErrorWithCode:(socketCustomErrorCode)code message:(NSString *)message{
    NSError *error = [[NSError alloc] initWithDomain:socketCustomErrorDomain
                                                code:code
                                            userInfo:@{@"errorInfo":(message == nil ? @"" : message)}];
    return error;
}

/**
 将第三方GCDAsyncSocket的error转换成自定义的error

 @param error GCDAsyncSocket的error
 @return 自定义error
 */
+ (NSError *)exchangedGCDAsyncSocketErrorToLocalError:(NSError *)error{
    if (!error || ![error isKindOfClass:[NSError class]]) {
        return nil;
    }
    NSString *domain = error.domain;
    if (![domain isEqualToString:GCDAsyncSocketErrorDomain]) {
        return nil;
    }
    //只转换GCDAsyncSocket的error
    socketCustomErrorCode code = [self customErrorCode:error.code];
    NSError *customError = [self getErrorWithCode:code message:error.userInfo[NSLocalizedDescriptionKey]];
    return customError;
}

+ (void)operationParamsErrorBlock:(void (^)(NSError *error))block{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) {
            block([self getErrorWithCode:socketParamsError message:@"params error"]);
        }
    });
}

+ (void)operationParamsErrorWithMessage:(NSString *)message block:(void (^)(NSError *error))block{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) {
            block([self getErrorWithCode:socketParamsError message:message]);
        }
    });
}

+ (void)operationGetDataErrorBlock:(void (^)(NSError *error))block{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) {
            block([self getErrorWithCode:socketRequestDataError message:@"get data error"]);
        }
    });
}

+ (void)operationDisConnectedErrorBlock:(void (^)(NSError *error))block{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) {
            block([self getErrorWithCode:socketDisconnected message:@"please connect device"]);
        }
    });
}

+ (void)operationDataErrorWithReturnData:(NSDictionary *)returnData block:(void (^)(NSError *error))block{
    if ([returnData[@"code"] integerValue] == 0) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) {
            block([self getErrorWithCode:socketSetParamsError message:returnData[@"message"]]);
        }
    });
}

+ (void)operationConnectTimeoutBlock:(void (^)(NSError *error))block{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) {
            block([self getErrorWithCode:socketConnectedFailed message:@"Connect device timeout"]);
        }
    });
}

#pragma mark - private method
+ (socketCustomErrorCode)customErrorCode:(GCDAsyncSocketError)socketErrorCode{
    switch (socketErrorCode) {
        case GCDAsyncSocketNoError:
            return socketNoError;
        case GCDAsyncSocketBadConfigError:
            return socketParamsError;
        case GCDAsyncSocketBadParamError:
            return socketParamsError;
        case GCDAsyncSocketConnectTimeoutError:
            return socketConnectedFailed;
        case GCDAsyncSocketReadTimeoutError:
            return socketRequestDataError;
        case GCDAsyncSocketWriteTimeoutError:
            return socketRequestDataError;
        case GCDAsyncSocketClosedError:
            return socketDisconnected;
        case GCDAsyncSocketReadMaxedOutError:
            return socketSetParamsError;
        case GCDAsyncSocketOtherError:
            return socketRequestDataError;
    }
}

@end
