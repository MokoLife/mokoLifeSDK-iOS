//
//  MKSocketTaskOperation.h
//  MKSmartPlug
//
//  Created by aa on 2018/6/6.
//  Copyright © 2018年 MK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MKSocketTaskDefine.h"

/**
 任务完成回调
 
 @param error 是否产生了超时错误
 @param operationID 当前任务ID
 @param returnData 返回的数据
 */
typedef void(^communicationCompleteBlock)(NSError *error, MKSocketOperationID operationID, id returnData);
@interface MKSocketTaskOperation : NSOperation<MKSocketOperationProtocol>

/**
 初始化通信线程
 
 @param operationID 当前线程的任务ID
 @param completeBlock 数据通信完成回调
 @return operation
 */
- (instancetype)initOperationWithID:(MKSocketOperationID)operationID
                      completeBlock:(communicationCompleteBlock)completeBlock;

@end
