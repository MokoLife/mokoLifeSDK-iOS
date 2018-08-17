//
//  MKMQTTServerDataParser.h
//  MKSmartPlug
//
//  Created by aa on 2018/6/22.
//  Copyright © 2018年 MK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MKMQTTServerDataParser : NSObject

+ (void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained;

@end
