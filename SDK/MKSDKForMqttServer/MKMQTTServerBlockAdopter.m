//
//  MKMQTTServerBlockAdopter.m
//  MKSmartPlug
//
//  Created by aa on 2018/6/22.
//  Copyright © 2018年 MK. All rights reserved.
//

#import "MKMQTTServerBlockAdopter.h"

NSString * const mqttServerCustomErrorDomain = @"com.moko.MKMQTTServerSDK";

@implementation MKMQTTServerBlockAdopter

+ (NSError *)getErrorWithCode:(serverCustomErrorCode)code message:(NSString *)message{
    NSError *error = [[NSError alloc] initWithDomain:mqttServerCustomErrorDomain
                                                code:code
                                            userInfo:@{@"errorInfo":(message == nil ? @"" : message)}];
    return error;
}

+ (void)operationDisConnectedErrorBlock:(void (^)(NSError *error))block{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) {
            block([self getErrorWithCode:serverDisconnected message:@"please connect server"]);
        }
    });
}

+ (void)operationTopicErrorBlock:(void (^)(NSError *error))block{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) {
            block([self getErrorWithCode:serverTopicError message:@"the theme of the error to publish information"]);
        }
    });
}

+ (void)operationSetDataErrorBlock:(void (^)(NSError *error))block{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) {
            block([self getErrorWithCode:serverSetParamsError message:@"set data error"]);
        }
    });
}

+ (void)operationParamsErrorBlock:(void (^)(NSError *error))block{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) {
            block([self getErrorWithCode:serverParamsError message:@"params error"]);
        }
    });
}

@end
