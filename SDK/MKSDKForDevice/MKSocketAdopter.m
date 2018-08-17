//
//  MKSocketAdopter.m
//  MKSmartPlug
//
//  Created by aa on 2018/6/5.
//  Copyright © 2018年 MK. All rights reserved.
//

#import "MKSocketAdopter.h"

@implementation MKSocketAdopter

+ (BOOL)isValidatIP:(NSString *)IPAddress{
    NSString  *urlRegEx =@"^([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
    "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
    "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
    "([01]?\\d\\d?|2[0-4]\\d|25[0-5])$";
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [pred evaluateWithObject:IPAddress];
}

+ (BOOL)isClientId:(NSString *)clientId{
    NSString *regex = @"^[a-zA-Z_][a-zA-Z0-9_]{5,19}$";
    NSPredicate *clientIdPre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    return [clientIdPre evaluateWithObject:clientId];
}

+ (BOOL)isUserName:(NSString *)userName{
    NSString *regex = @"^[a-zA-Z_][a-zA-Z0-9_]{5,19}$";
    NSPredicate *userNamePre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    return [userNamePre evaluateWithObject:userName];
}

+ (BOOL)isPassword:(NSString *)password{
    NSString *regex = @"^[a-zA-Z0-9_]{5,19}$$";
    NSPredicate *passwordPre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    return [passwordPre evaluateWithObject:password];
}

+ (BOOL)isDomainName:(NSString *)host{
    NSString *regex =@"[a-zA-z]+://[^\\s]*";
    NSPredicate *hostTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    return [hostTest evaluateWithObject:host];
}

/**
 字典转json字符串方法
 
 @param dict json
 @return string
 */
+ (NSString *)convertToJsonData:(NSDictionary *)dict{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    if (!jsonData) {
        return nil;
    }
    NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (!jsonString || jsonString.length == 0) {
        return nil;
    }
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    NSRange range = {0,jsonString.length};
    //去掉字符串中的空格
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    NSRange range2 = {0,mutStr.length};
    //去掉字符串中的换行符
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    return mutStr;
}

/**
 JSON字符串转化为字典

 @param jsonString string
 @return dic
 */
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString{
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err){
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

@end
