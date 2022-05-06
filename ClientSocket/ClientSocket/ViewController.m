//
//  ViewController.m
//  ClientSocket
//
//  Created by 邓亚洲 on 2022/5/6.
//

#import "ViewController.h"
#import "Socket/SocketViewController.h"
#import "Socket/GCDSocketViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"第一页";
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
#pragma mark 2、CocoaAsyncSocket的GCDAsyncSocket
    GCDSocketViewController *vc = [[GCDSocketViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
    
#pragma mark 1、socket
//    SocketViewController *vc = [[SocketViewController alloc] init];
//    [self.navigationController pushViewController:vc animated:YES];
    
}


@end
