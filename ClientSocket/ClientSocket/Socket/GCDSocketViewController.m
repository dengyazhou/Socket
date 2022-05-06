//
//  GCDSocketViewController.m
//  ClientSocket
//
//  Created by 邓亚洲 on 2022/5/6.
//

#import "GCDSocketViewController.h"
#import <Masonry/Masonry.h>

#import <CocoaAsyncSocket/GCDAsyncSocket.h>

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@interface GCDSocketViewController () <GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *socket;

@property (nonatomic, assign) int clientId;

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) NSMutableAttributedString *totolAttributeStr;
@property (nonatomic, copy) NSString *recoderTime;

@property (nonatomic, assign) Boolean clientClose;//客户端自己下掉自己，判断字段

@end

@implementation GCDSocketViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"ClientSocket";
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    
    UIButton *btnConnect = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnConnect setTitle:@"建立连接" forState:UIControlStateNormal];
    [btnConnect addTarget:self action:@selector(socketConnectAction:) forControlEvents:UIControlEventTouchUpInside];
    btnConnect.backgroundColor = [UIColor redColor];
    btnConnect.titleLabel.font = [UIFont systemFontOfSize:13];
    [self.view addSubview:btnConnect];
    [btnConnect mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(100);
        make.left.offset(20);
        make.size.mas_equalTo(CGSizeMake(80, 50));
    }];
    
    UIButton *btnSend = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnSend setTitle:@"发送消息" forState:UIControlStateNormal];
    [btnSend addTarget:self action:@selector(sendMsgAction:) forControlEvents:UIControlEventTouchUpInside];
    btnSend.backgroundColor = [UIColor redColor];
    btnSend.titleLabel.font = [UIFont systemFontOfSize:13];
    [self.view addSubview:btnSend];
    [btnSend mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(btnConnect);
        make.left.equalTo(btnConnect.mas_right).offset(10);
        make.size.equalTo(btnConnect);
    }];
    
    UIButton *btnClose = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnClose setTitle:@"关闭自己" forState:UIControlStateNormal];
    [btnClose addTarget:self action:@selector(closeAction:) forControlEvents:UIControlEventTouchUpInside];
    btnClose.backgroundColor = [UIColor redColor];
    btnClose.titleLabel.font = [UIFont systemFontOfSize:13];
    [self.view addSubview:btnClose];
    [btnClose mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(btnConnect);
        make.left.equalTo(btnSend.mas_right).offset(10);
        make.size.equalTo(btnConnect);
    }];
    
    UITextField *textField = [[UITextField alloc] init];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:textField];
    self.textField = textField;
    [textField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(btnConnect.mas_bottom).offset(10);
        make.left.offset(20);
        make.right.offset(-20);
        make.height.mas_equalTo(40);
    }];
    
    UITextView *textView = [[UITextView alloc] init];
    textView.backgroundColor = [UIColor cyanColor];
    [self.view addSubview:textView];
    self.textView = textView;
    [textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(textField.mas_bottom).offset(10);
        make.left.offset(20);
        make.right.offset(-20);
        make.bottom.offset(-60);
    }];
    
    self.textView.editable = NO;
    self.totolAttributeStr = [[NSMutableAttributedString alloc] init];
}

#pragma mark 创建socket建立连接
- (void)socketConnectAction:(UIButton *)sender {
    //1、创建socket
    if (!self.socket) {
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    }
    
    //2、链接socket
    if (!self.socket.isConnected) {
        NSError *error;
        [self.socket connectToHost:@"192.168.0.104" onPort:8040 error:&error];
        if (error) {
            NSLog(@"%@",error);
        }
    }
}

#pragma mark 发送消息
- (void)sendMsgAction:(UIButton *)sender {
    if (self.textField.text.length == 0) {
        return;
    }
    NSData *data = [self.textField.text dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:data withTimeout:-1 tag:10010];
}


#pragma mark 关闭
- (void)closeAction:(UIButton *)sender {
    [self.socket disconnect];
    self.socket = nil;
}

#pragma mark GCDAsyncSocketDelegate
//已经连接到服务器
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"链接socket 成功:%@-%d",host,port);
    [self.socket readDataWithTimeout:-1 tag:10010];
}

//消息发送成功的回调
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"tag:%ld 发送数据成功",tag);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMsg:self.textField.text msgType:0];
    });
}

//接收服务器返回数据的回调
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"tag:%ld %@",tag,str);
    [self.socket readDataWithTimeout:-1 tag:10010];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMsg:str msgType:1];
    });
}

// 连接断开
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"断开socket 链接:%@",err);
}




#pragma mark private

- (void)showMsg:(NSString *)msg msgType:(int)msgType {
    NSString *showTimeStr = [self getCurrentTime];
    if (showTimeStr) {
        NSMutableAttributedString *dateAttributedString = [[NSMutableAttributedString alloc] initWithString:showTimeStr];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        // 对齐方式
        paragraphStyle.alignment = NSTextAlignmentCenter;
        [dateAttributedString addAttributes:@{
            NSFontAttributeName:[UIFont systemFontOfSize:13],
            NSForegroundColorAttributeName:[UIColor blackColor],
            NSParagraphStyleAttributeName:paragraphStyle
        } range:NSMakeRange(0, showTimeStr.length)];
        [self.totolAttributeStr appendAttributedString:dateAttributedString];
        [self.totolAttributeStr appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n"]];
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.headIndent = 20.f;
    NSMutableAttributedString *attributedString;
    if (msgType == 0) {//自己发送的消息
        attributedString = [[NSMutableAttributedString alloc] initWithString:msg];
        paragraphStyle.alignment = NSTextAlignmentRight;
        [attributedString addAttributes:@{
            NSFontAttributeName:[UIFont systemFontOfSize:15],
            NSForegroundColorAttributeName:[UIColor whiteColor],
            NSBackgroundColorAttributeName:[UIColor orangeColor],
            NSParagraphStyleAttributeName:paragraphStyle
        } range:NSMakeRange(0, msg.length)];
    } else {
        attributedString = [[NSMutableAttributedString alloc] initWithString:msg];
        [attributedString addAttributes:@{
            NSFontAttributeName:[UIFont systemFontOfSize:15],
            NSForegroundColorAttributeName:[UIColor blackColor],
            NSBackgroundColorAttributeName:[UIColor whiteColor],
            NSParagraphStyleAttributeName:paragraphStyle
        } range:NSMakeRange(0, msg.length)];
    }
    [self.totolAttributeStr appendAttributedString:attributedString];
    [self.totolAttributeStr appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n"]];
    
    self.textView.attributedText = self.totolAttributeStr;
    
}

- (NSString *)getCurrentTime{
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *dateStr = [dateFormatter stringFromDate:date];
    if (!self.recoderTime || self.recoderTime.length == 0) {
        self.recoderTime = dateStr;
        return dateStr;
    }
    NSDate *recoderDate = [dateFormatter dateFromString:self.recoderTime];
    self.recoderTime = dateStr;
    NSTimeInterval timeInter = [date timeIntervalSinceDate:recoderDate];
//    NSLog(@"%@--%@ -- %f",date,recoderDate,timeInter);
    if (timeInter<6) {
        return @" ";
    }
    return dateStr;
}




/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
