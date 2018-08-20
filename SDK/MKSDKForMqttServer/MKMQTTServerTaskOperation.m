//
//  MKMQTTServerTaskOperation.m
//  MKSmartPlug
//
//  Created by aa on 2018/6/23.
//  Copyright © 2018年 MK. All rights reserved.
//

#import "MKMQTTServerTaskOperation.h"

@interface MKMQTTServerTaskOperation()

@property (nonatomic, copy)void (^completeBlock)(NSError *error, NSInteger operationID);

@property (nonatomic, assign)NSInteger taskID;

/**
 是否结束当前线程的标志
 */
@property (nonatomic, assign)BOOL complete;

/**
 超过5s没有接收到新的数据，超时
 */
@property (nonatomic, strong)dispatch_source_t receiveTimer;

@property (nonatomic, assign)NSInteger receiveTimerCount;

@property (nonatomic, assign)BOOL timeout;

@end

@implementation MKMQTTServerTaskOperation
@synthesize executing = _executing;
@synthesize finished = _finished;

- (void)dealloc{
    NSLog(@"MKMQTTServerTaskOperation任务销毁");
}

/**
 初始化通信线程
 
 @param operationID 当前线程的任务ID
 @param completeBlock 数据通信完成回调
 @return operation
 */
- (instancetype)initOperationWithID:(NSInteger)operationID
                      completeBlock:(void (^)(NSError *error, NSInteger operationID))completeBlock{
    if (self = [super init]) {
        _executing = NO;
        _finished = NO;
        _completeBlock = completeBlock;
        _taskID = operationID;
    }
    return self;
}

#pragma mark - super method
- (void)main{
    @try {
        @autoreleasepool{
            [self startListen];
        }
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@", exception);
    } @finally {
        
    }
}

- (void)start{
    if (self.isFinished || self.isCancelled) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

#pragma mark - MKMQTTServerOperationProtocol
- (void)sendMessageSuccess:(NSInteger)operationID{
    if (self.isCancelled || !_executing || self.timeout) {
        return;
    }
    if (operationID != self.taskID) {
        return;
    }
    if (self.receiveTimer) {
        dispatch_cancel(self.receiveTimer);
    }
    [self finishOperation];
    if (self.completeBlock) {
        self.completeBlock(nil, self.taskID);
    }
}

#pragma mark - private method
- (void)startListen{
    if (self.isCancelled) {
        return;
    }
    __weak __typeof(&*self)weakSelf = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.receiveTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    //当2s内没有接收到新的数据的时候，也认为是接受超时
    dispatch_source_set_timer(self.receiveTimer, dispatch_walltime(NULL, 0), 0.1 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(self.receiveTimer, ^{
        if (weakSelf.timeout || weakSelf.receiveTimerCount >= 50.f) {
            //接受数据超时
            weakSelf.receiveTimerCount = 0;
            [weakSelf communicationTimeout];
            return ;
        }
        weakSelf.receiveTimerCount ++;
    });
    if (self.isCancelled) {
        return;
    }
    //如果需要从外设拿总条数，则在拿到总条数之后，开启接受超时定时器
    dispatch_resume(self.receiveTimer);
    do {
        [[NSRunLoop currentRunLoop] runMode:NSRunLoopCommonModes beforeDate:[NSDate distantFuture]];
    }while (NO == _complete);
}

- (void)finishOperation{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = NO;
    [self didChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    _finished = YES;
    [self didChangeValueForKey:@"isFinished"];
    _complete = YES;
}

- (void)communicationTimeout{
    self.timeout = YES;
    if (self.receiveTimer) {
        dispatch_cancel(self.receiveTimer);
    }
    [self finishOperation];
    if (self.completeBlock) {
        NSError *error = [[NSError alloc] initWithDomain:@"com.moko.MKMQTTServerSDK"
                                                    code:-999
                                                userInfo:@{@"errorInfo":@"Communication timeout"}];
        self.completeBlock(error, self.taskID);
    }
}

#pragma mark - setter & getter
- (BOOL)isConcurrent{
    return YES;
}

- (BOOL)isFinished{
    return _finished;
}

- (BOOL)isExecuting{
    return _executing;
}

@end
