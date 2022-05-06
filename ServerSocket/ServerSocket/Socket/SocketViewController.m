//
//  SocketViewController.m
//  ServerSocket
//
//  Created by xmly on 2022/5/6.
//

#import "SocketViewController.h"
#import <Masonry/Masonry.h>

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

static int const kMaxConnectCount = 5;

@interface SocketViewController ()

@property (nonatomic, assign) int serverId;
@property (nonatomic, strong) NSMutableArray *clientSockets;

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) NSMutableAttributedString *totolAttributeStr;
@property (nonatomic, copy) NSString *recoderTime;

@end

@implementation SocketViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"ServerSocket";
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
        make.height.mas_equalTo(50);
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
    [btnClose setTitle:@"关闭客户端" forState:UIControlStateNormal];
    [btnClose addTarget:self action:@selector(closeClientAction:) forControlEvents:UIControlEventTouchUpInside];
    btnClose.backgroundColor = [UIColor redColor];
    btnClose.titleLabel.font = [UIFont systemFontOfSize:13];
    [self.view addSubview:btnClose];
    [btnClose mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(btnConnect);
        make.left.equalTo(btnSend.mas_right).offset(10);
        make.size.equalTo(btnConnect);
    }];
    
    UIButton *btnCloseServer = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnCloseServer setTitle:@"关闭服务端" forState:UIControlStateNormal];
    [btnCloseServer addTarget:self action:@selector(closeServerAction:) forControlEvents:UIControlEventTouchUpInside];
    btnCloseServer.backgroundColor = [UIColor redColor];
    btnCloseServer.titleLabel.font = [UIFont systemFontOfSize:13];
    [self.view addSubview:btnCloseServer];
    [btnCloseServer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(btnConnect);
        make.left.equalTo(btnClose.mas_right).offset(10);
        make.right.offset(-20);
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
    //AF_INET、AF_INET6
    self.serverId = socket(AF_INET, SOCK_STREAM, 0);
    if (self.serverId == -1) {
        NSLog(@"创建socket 失败");
        return;
    }
    self.clientSockets = [[NSMutableArray alloc] initWithCapacity:kMaxConnectCount];
    NSLog(@"创建socket 成功 serverId:%d",self.serverId);
    
    
    struct sockaddr_in socketAddr;
    socketAddr.sin_family = AF_INET;
    socketAddr.sin_port = htons(8040);
    
    struct in_addr socketIn_addr;
    socketIn_addr.s_addr = inet_addr("192.168.0.104");//服务器自己的ip
    socketAddr.sin_addr = socketIn_addr;
   
    //2、绑定socket
    int bind_result = bind(self.serverId, (const struct sockaddr *)&socketAddr, sizeof(socketAddr));
    if (bind_result == -1) {
        NSLog(@"绑定socket 失败");
        return;
    }
    NSLog(@"绑定socket 成功");
    
    //3、监听socket
    int listen_result = listen(self.serverId, kMaxConnectCount);
    if (listen_result == -1) {
        NSLog(@"监听socket 失败");
        return;
    }
    NSLog(@"监听socket 成功");
    
    //4、接受客户端的链接
    for (int i = 0; i < kMaxConnectCount; i++) {
        [self acceptClientConnet];
    }
}

- (void)acceptClientConnet {
    //阻塞线程
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        struct sockaddr_in client_address;
        socklen_t address_len;
        
        //accept函数 会阻塞线程 所以异步处理
        NSLog(@"====>>>>：accept 前");
        int client_socket = accept(self.serverId, (struct sockaddr *)&client_address, &address_len);
        NSLog(@"====>>>>：accept 后");
        [self.clientSockets addObject:@(client_socket)];
        if (client_socket == -1) {
            NSLog(@"接收 %u 客户端错误",address_len);
        } else {
            NSString *acceptInfo = [NSString stringWithFormat:@"客户端 in，socket：%d",client_socket];
            NSLog(@"%@",acceptInfo);
            [self receiveMsgWithClientSocket:client_socket];
        }
    });
}

- (void)receiveMsgWithClientSocket:(int)clientSocket {
    while (1) {
        // 5、接受客户端传来的数据
        char buf[1024] = {0};
        //recv函数 会阻塞线程
        NSLog(@"====>>>>：recv 前");
        long iReturn = recv(clientSocket, buf, 1024, 0);
        NSLog(@"====>>>>：recv 后");
        if (iReturn > 0) {
            NSLog(@"客户端来消息了");
            NSData *recvData = [NSData dataWithBytes:buf length:iReturn];
            NSString *recvStr = [[NSString alloc] initWithData:recvData encoding:NSUTF8StringEncoding];
            NSLog(@"%@",recvStr);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showMsg:recvStr msgType:1];
            });
        } else if (iReturn == -1) {
            NSLog(@"读取消息失败");
            break;
        } else if (iReturn == 0) {
            NSLog(@"客户端走了");
            close(clientSocket);
            [self.clientSockets removeObject:@(clientSocket)];
            break;
        }
    }
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

#pragma mark 发送消息
- (void)sendMsgAction:(UIButton *)sender {
    if (self.textField.text.length == 0) {
        return;
    }
    const char *msg = self.textField.text.UTF8String;
    for (int i = 0; i < self.clientSockets.count; i++) {//给连上的所有人发消息，也可以单独给某一个发
        int client_socket = [(NSNumber *)self.clientSockets[i] intValue];
        size_t sendLen = send(client_socket, msg, strlen(msg), 0);
        if (sendLen == -1) {
            NSLog(@"消息发送失败");
            return;
        }
        NSLog(@"发送了:%ld字节",sendLen);
        [self showMsg:self.textField.text msgType:0];
    }
}

#pragma mark 关闭客户端
- (void)closeClientAction:(UIButton *)sender {
    for (int i = 0; i < self.clientSockets.count; i++) {
        int client_socket = [(NSNumber *)self.clientSockets[i] intValue];
        int close_result = close(client_socket);//关闭客户端链接
        if (close_result == -1) {
            NSLog(@"关闭socket 失败");
            return;
        }
        NSLog(@"关闭socket 成功");
    }
    [self.clientSockets removeAllObjects];
}

#pragma mark 关闭服务端
- (void)closeServerAction:(UIButton *)sender {
    int close_result = close(self.serverId);//关闭服务端
    if (close_result == -1) {
        NSLog(@"关闭服务端socket 失败");
        return;
    }
    NSLog(@"关闭服务端socket 成功");
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
