//
//  MKTestViewController.m
//  MokoLifeSDKDemo
//
//  Created by aa on 2018/8/20.
//  Copyright © 2018年 MK. All rights reserved.
//

#import "MKTestViewController.h"
#import "MKMQTTServerManager.h"

@interface MKTestViewController ()

@property (nonatomic, strong)UIButton *connectServer;

@end

@implementation MKTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.navigationItem setTitle:@"test"];
    [self.view addSubview:self.connectServer];
    // Do any additional setup after loading the view.
}

#pragma mark - event method
- (void)connectServerButtonPressed{
    [[MKMQTTServerManager sharedInstance] connectMQTTServer:@"47.104.81.55" port:1883 tls:NO keepalive:60 clean:YES auth:NO user:@"a" pass:@"a" clientId:@"testConnectIdenty"];
}

#pragma mark - setter & getter
- (UIButton *)connectServer{
    if (!_connectServer) {
        _connectServer = [UIButton buttonWithType:UIButtonTypeCustom];
        _connectServer.frame = CGRectMake(15, 100, self.view.frame.size.width - 2 * 15, 50.f);
        [_connectServer setBackgroundColor:[UIColor blueColor]];
        [_connectServer setTitle:@"Connect" forState:UIControlStateNormal];
        [_connectServer addTarget:self action:@selector(connectServerButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _connectServer;
}

@end
