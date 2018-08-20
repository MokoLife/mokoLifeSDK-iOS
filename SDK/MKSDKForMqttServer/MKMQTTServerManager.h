//
//  MKMQTTServerManager.h
//  MKSmartPlug
//
//  Created by aa on 2018/6/8.
//  Copyright  2018ƒÍ MK. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MKMQTTSessionManagerState) {
    MKMQTTSessionManagerStateStarting,
    MKMQTTSessionManagerStateConnecting,
    MKMQTTSessionManagerStateError,
    MKMQTTSessionManagerStateConnected,
    MKMQTTSessionManagerStateClosing,
    MKMQTTSessionManagerStateClosed
};

@class MKMQTTServerManager;
@protocol MKMQTTServerManagerDelegate <NSObject>

- (void)mqttServerManagerStateChanged:(MKMQTTSessionManagerState)state;

- (void)sessionManager:(MKMQTTServerManager *)sessionManager didReceiveMessage:(NSData *)data onTopic:(NSString *)topic;

@end

@interface MKMQTTServerManager : NSObject

@property (nonatomic, assign, readonly)MKMQTTSessionManagerState managerState;

@property (nonatomic, weak)id <MKMQTTServerManagerDelegate>delegate;

+ (MKMQTTServerManager *)sharedInstance;
/**
 Connect to the MQTT server
 
 @param host           Server address
 @param port           Server port
 @param tls            Whether to use the TLS protocol
 @param keepalive      Heartbeat package time, the range is 60~120, and unitis °∞s°±
 @param clean session  Whether to clear or not, this should be noted, if false, means to remain logged in, and if the client is offline again, an offline message can be received
 @param auth           Use login validation
 @param user           Username
 @param pass           Password
 @param clientId       It should be noted that this id needs to be globally unique, because the server is to distinguish different clients according to this. By default, if one id is logged in, if another connection is logged in with this same id, the last connection will be offline.
 */
- (void)connectMQTTServer:(NSString *)host
                     port:(NSInteger)port
                      tls:(BOOL)tls
                keepalive:(NSInteger)keepalive
                    clean:(BOOL)clean
                     auth:(BOOL)auth
                     user:(NSString *)user
                     pass:(NSString *)pass
                 clientId:(NSString *)clientId;

/**
 Disconnect
 */
- (void)disconnect;

/**
 Subscribe the topic

 @param topicList topicList
 */
- (void)subscriptions:(NSArray <NSString *>*)topicList;

/**
 Unsubscribe the topic
 
 @param topicList topicList
 */
- (void)unsubscriptions:(NSArray <NSString *>*)topicList;

/**
 Send data

 @param data data
 @param topic topic
 @param sucBlock success callback
 @param failedBlock failed callback
 */
- (void)sendData:(NSDictionary *)data
           topic:(NSString *)topic
        sucBlock:(void (^)(void))sucBlock
     failedBlock:(void (^)(NSError *error))failedBlock;

@end

