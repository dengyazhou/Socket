//
//  SocketViewController.m
//  ClientSocket
//
//  Created by 邓亚洲 on 2022/5/6.
//

#import "SocketViewController.h"
#import <Masonry/Masonry.h>

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@interface SocketViewController ()

@property (nonatomic, assign) int clientId;

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) NSMutableAttributedString *totolAttributeStr;
@property (nonatomic, copy) NSString *recoderTime;

@property (nonatomic, assign) Boolean clientClose;//客户端自己下掉自己，判断字段

@end

@implementation SocketViewController

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
    NSLog(@"%s",__func__);
    
    //1、创建socket
    self.clientId = socket(AF_INET, SOCK_STREAM, 0);
    if (self.clientId == -1) {
        NSLog(@"创建socket 失败");
        return;
    }
    self.clientClose = NO;
    NSLog(@"创建socket 成功 clientId:%d",self.clientId);
    
    
    struct sockaddr_in socketAddr;
    socketAddr.sin_family = AF_INET;
    socketAddr.sin_port = htons(8040);
    
    struct in_addr socketIn_addr;
    socketIn_addr.s_addr = inet_addr("192.168.0.104");//需要链接的服务器的ip
    socketAddr.sin_addr = socketIn_addr;
    
    //2、链接socket
    int connect_result = connect(self.clientId, (const struct sockaddr *)&socketAddr, sizeof(socketAddr));
    if (connect_result != 0) {
        NSLog(@"链接socket 失败");
        return;
    }
    NSLog(@"链接socket 成功");
    
    //发送数据
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self recvMsg];
    });
}

- (void)recvMsg {
    while (1) {
        uint8_t buffer[1024];
        NSLog(@"====>>>>：recv 前");
        size_t iReturn = recv(self.clientId, buffer, sizeof(buffer), 0);
        NSLog(@"====>>>>：recv 后");
        
        if (iReturn > 0) {
            NSLog(@"服务端来消息了");
            if (self.clientClose == YES) {
                NSLog(@"客户端自己关闭了自己");
                break;;
            }
            NSData *recvdata = [NSData dataWithBytes:buffer length:iReturn];
            NSString *recvStr = [[NSString alloc] initWithData:recvdata encoding:NSUTF8StringEncoding];
            NSLog(@"%@",recvStr);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showMsg:recvStr msgType:1];
            });
        } else if (iReturn == -1) {
            NSLog(@"读取消息失败");
            break;
        } else if (iReturn == 0) {
            NSLog(@"服务端把我关闭了");
            close(self.clientId);//如果被服务端下掉了，自己需要下线，都这再调用发送消息会崩溃
            break;
        }
    }
}

#pragma mark 发送消息
- (void)sendMsgAction:(UIButton *)sender {
    NSLog(@"%s",__func__);
    if (self.textField.text.length == 0) {
        return;
    }
    const char *msg = self.textField.text.UTF8String;
    size_t sendLen = send(self.clientId, msg, strlen(msg), 0);
    if (sendLen == -1) {
        NSLog(@"消息发送失败");
    }
    NSLog(@"发送 %ld 字节",sendLen);
    [self showMsg:self.textField.text msgType:0];
}

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

#pragma mark 关闭
- (void)closeAction:(UIButton *)sender {
    NSLog(@"%s",__func__);
    int close_result = close(self.clientId);
    if (close_result == -1) {
        NSLog(@"关闭socket 失败");
        return;
    }
    self.clientClose = YES;
    NSLog(@"关闭socket 成功");
    
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
