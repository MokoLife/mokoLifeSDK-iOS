//
//  MKMQTTServerManager.h
//  MKSmartPlug
//
//  Created by aa on 2018/6/8.
//  Copyright  2018ƒÍ MK. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MKFirmwareUpdateHostType) {
    MKFirmwareUpdateHostTypeIP,
    MKFirmwareUpdateHostTypeUrl,
};

typedef NS_ENUM(NSInteger, MKMQTTSessionManagerState) {
    MKMQTTSessionManagerStateStarting,
    MKMQTTSessionManagerStateConnecting,
    MKMQTTSessionManagerStateError,
    MKMQTTSessionManagerStateConnected,
    MKMQTTSessionManagerStateClosing,
    MKMQTTSessionManagerStateClosed
};

@protocol MKMQTTServerManagerStateChangedDelegate <NSObject>

- (void)mqttServerManagerStateChanged:(MKMQTTSessionManagerState)state;

@end

@interface MKMQTTServerManager : NSObject

@property (nonatomic, assign, readonly)MKMQTTSessionManagerState managerState;

@property (nonatomic, weak)id <MKMQTTServerManagerStateChangedDelegate>stateDelegate;

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
 Sets the switch state of the plug
 
 @param isOn           YES:ON£¨NO:OFF
 @param topic          Publish switch state topic
 @param sucBlock       Success callback
 @param failedBlock    Failed callback
 */
- (void)setSmartPlugSwitchState:(BOOL)isOn
                          topic:(NSString *)topic
                       sucBlock:(void (^)(void))sucBlock
                    failedBlock:(void (^)(NSError *error))failedBlock;
/**
 Plug for countdown. When the time is up, The socket will switch on/off according to the countdown settings
 
 @param delay_hour     Hour range:0~23
 @param delay_minutes  Minute range:0~59
 @param topic          Publish countdown topic
 @param sucBlock       Success callback
 @param failedBlock    Failed callback
 */
- (void)setDelayHour:(NSInteger)delay_hour
            delayMin:(NSInteger)delay_minutes
               topic:(NSString *)topic
            sucBlock:(void (^)(void))sucBlock
         failedBlock:(void (^)(NSError *error))failedBlock;

/**
 Factory Reset
 
 @param topic topic
 @param sucBlock       Success callback
 @param failedBlock    Failed callback
 */
- (void)resetDeviceWithTopic:(NSString *)topic
                    sucBlock:(void (^)(void))sucBlock
                 failedBlock:(void (^)(NSError *error))failedBlock;

/**
 Read device information
 
 @param topic topic
 @param sucBlock      Success callback
 @param failedBlock   Failed callback
 */
- (void)readDeviceFirmwareInformationWithTopic:(NSString *)topic
                                      sucBlock:(void (^)(void))sucBlock
                                   failedBlock:(void (^)(NSError *error))failedBlock;
/**
 Plug OTA upgrade
 
 @param hostType hostType
 @param host          The IP address or domain name of the new firmware host
 @param port          Range£∫0~65535
 @param catalogue     The length is less than 100 bytes
 @param topic         Firmware upgrade topic
 @param sucBlock      Success callback
 @param failedBlock   Failed callback
 */
- (void)updateFirmware:(MKFirmwareUpdateHostType)hostType
                  host:(NSString *)host
                  port:(NSInteger)port
             catalogue:(NSString *)catalogue
                 topic:(NSString *)topic
              sucBlock:(void (^)(void))sucBlock
           failedBlock:(void (^)(NSError *error))failedBlock;
@end

