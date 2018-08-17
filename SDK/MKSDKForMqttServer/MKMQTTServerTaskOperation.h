//
//  MKMQTTServerTaskOperation.h
//  MKSmartPlug
//
//  Created by aa on 2018/6/23.
//  Copyright © 2018年 MK. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MKMQTTServerOperationProtocol <NSObject>

- (void)sendMessageSuccess:(NSInteger)operationID;

@end

@interface MKMQTTServerTaskOperation : NSOperation<MKMQTTServerOperationProtocol>

/**
 初始化通信线程
 
 @param operationID 当前线程的任务ID
 @param completeBlock 数据通信完成回调
 @return operation
 */
- (instancetype)initOperationWithID:(NSInteger)operationID
                      completeBlock:(void (^)(NSError *error, NSInteger operationID))completeBlock;

@end
