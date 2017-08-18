//
//  FMLoginViewController.m
//  FruitMix
//
//  Created by wisnuc on 2017/8/14.
//  Copyright © 2017年 WinSun. All rights reserved.
//

#import "FMLoginViewController.h"
#import "StationPageControl.h"
#import "LoginTableViewCell.h"
#import "FMUserLoginViewController.h"
#import "ServerBrowser.h"
#import "GCDAsyncSocket.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "LoginModel.h"

#define kCount 3
@interface FMLoginViewController ()
<
UIScrollViewDelegate,
UITableViewDelegate,
UITableViewDataSource,
ServerBrowserDelegate
>
{
    NSMutableArray *_dataSource;
    ServerBrowser* _browser;
    AFNetworkReachabilityManager * _manager;
    NSTimer* _reachabilityTimer;
}
@property (strong, nonatomic) UIScrollView *stationScrollView;
@property (strong, nonatomic) UIView *stationCardView;
@property (strong, nonatomic) StationPageControl *stationPageControl;
@property (strong, nonatomic) UIButton *infoButton;
@property (strong, nonatomic) UIImageView *logoImageView;
@property (strong, nonatomic) UIImageView *stationLogoImageView;
@property (strong, nonatomic) UILabel *stationNameLabel;
@property (strong, nonatomic) UILabel *stationTypeLabel;
@property (strong, nonatomic) UILabel *stationIpLabel;
@property (strong, nonatomic) UIView *userView;
@property (strong, nonatomic) UITableView *userListTableViwe;
@property (strong, nonatomic) UIView *wechatView;
@property (strong, nonatomic) NSMutableArray *tempDataSource;
@property (nonatomic) FMSerachService * expandCell;
@end

@implementation FMLoginViewController

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
//    [self.navigationController.navigationBar setBackgroundColor:UICOLOR_RGB(0x0288d1)];
    [UIApplication sharedApplication].statusBarStyle =UIStatusBarStyleLightContent;
    [self beginSearching];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)dealloc{
    [_reachabilityTimer invalidate];
    _reachabilityTimer = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _dataSource = [NSMutableArray arrayWithCapacity:0];
    [self beginSearching];
    [self.view addSubview:self.stationScrollView];
    [self setStationCardView];
    [self.view addSubview:self.stationPageControl];
    [self.view addSubview:self.logoImageView];
    [self.view addSubview:self.userView];
    [self.view addSubview:self.userListTableViwe];
    [self.view addSubview:self.wechatView];
     _reachabilityTimer =  [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(refreshDatasource) userInfo:nil repeats:YES];
}

- (void)beginSearching {
//    [self viewOfSeaching:YES];
    _browser = [[ServerBrowser alloc] initWithServerType:@"_http._tcp" port:-1];
    _browser.delegate = self;
    double delayInSeconds = 6.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        [self viewOfSeaching:NO];
        NSLog(@"发现 %lu 台设备",(unsigned long)_browser.discoveredServers.count);
    });
}

- (void)serverBrowserFoundService:(NSNetService *)service {
    for (NSData * address in service.addresses) {
        NSString* addressString = [GCDAsyncSocket hostFromAddress:address];
        [self findIpToCheck:addressString andService:service];
    }
}

- (void)serverBrowserLostService:(NSNetService *)service index:(NSUInteger)index {
    if (_browser.discoveredServers.count <= 0) {
        [self beginSearching];
    }
}

- (void)findIpToCheck:(NSString *)addressString andService:(NSNetService *)service{
    NSString* urlString = [NSString stringWithFormat:@"http://%@:3000/", addressString];
    NSLog(@"%@", urlString);
    FMSerachService * ser = [FMSerachService new];
    ser.path = urlString;
    ser.name = service.name;
    ser.type = service.type;
    ser.displayPath = addressString;
    ser.hostName = service.hostName;
    NSLog(@"%@",service.hostName);
    BOOL isNew = YES;
    for (FMSerachService * s in _dataSource) {
        if (IsEquallString(s.path, ser.path)) {
            isNew = NO;
            break;
        }
    }
    if (isNew) {
        [_dataSource addObject:ser];
        [self refreshDatasource];
    }
}


-(void)refreshDatasource{
    NSMutableArray * temp = [NSMutableArray arrayWithCapacity:0];
    for (FMSerachService * ser in _dataSource) {
        if (ser.isReadly) {
            [temp addObject:ser];
        }
    }
    
    if(self.tempDataSource.count != temp.count){
        self.tempDataSource = temp;
        [self.userListTableViwe reloadData];
     
    }
    
    for (UIView *view in _stationScrollView.subviews) {
          [view removeFromSuperview];
    }
    [self updateInfo];
    [self setStationCardView];
     NSLog(@"😆%@,😜%@🍄",_dataSource,_tempDataSource);
}

- (void)updateInfo{
    for (FMSerachService *ser in self.tempDataSource) {
        _stationIpLabel.text = ser.displayPath;
    }
  
    _stationScrollView.contentSize = CGSizeMake(self.tempDataSource.count * JYSCREEN_WIDTH, 0);
}

- (void)setStationCardView{

    for (int i = 0; i<self.tempDataSource.count; i++) {
        _stationCardView = [[UIView alloc]init];
        _stationCardView.backgroundColor =  UICOLOR_RGB(0x03a9f4);
        _stationCardView.frame = CGRectMake(i*JYSCREEN_WIDTH + 32,64,JYSCREEN_WIDTH - 32*2, 166);
        _stationCardView.layer.cornerRadius = 8;
        _stationCardView.layer.masksToBounds = YES;
        [self.stationScrollView addSubview:self.stationCardView];
        
        [self setInfoButton];
        [self setStationLogoImageView];
        [self setInfo];
    }
}

- (void)setInfoButton{
    UIImage *infoImage = [UIImage imageNamed:@"info"];
    _infoButton = [[UIButton alloc]init];
    [_infoButton setImage:infoImage forState:UIControlStateNormal];
    [_infoButton addTarget:self action:@selector(infoButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [_stationCardView addSubview:self.infoButton];
    [_infoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_stationCardView.mas_right).offset(-16);
        make.centerY.equalTo(_stationCardView);
        make.size.mas_equalTo(infoImage.size);
    }];
}

- (void)setStationLogoImageView{
    UIImage *logo = [UIImage imageNamed:@"stationLogo"];
    _stationLogoImageView = [[UIImageView alloc]initWithImage:logo];
    [self.stationCardView addSubview:self.stationLogoImageView];
    [_stationLogoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_stationCardView.mas_left).offset(16);
        make.centerY.equalTo(_stationCardView);
        make.size.mas_equalTo(logo.size);
    }];
}

- (void)setInfo{
//    cell.DeviceNameLb.text = ser.name;
//    cell.disPlayLb.text = ser.displayPath;
    _stationTypeLabel = [[UILabel alloc]init];
    _stationTypeLabel.text = @"我的设备";
    _stationTypeLabel.font = [UIFont systemFontOfSize:14];
    _stationTypeLabel.textColor = [UIColor whiteColor];
    _stationTypeLabel.alpha = 0.54;
    [self.stationCardView addSubview:self.stationTypeLabel];
    [_stationTypeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_stationLogoImageView.mas_right).offset(16);
        make.right.equalTo(_infoButton.mas_left).offset(-16);
        make.centerY.equalTo(_stationCardView.mas_centerY).offset(2);
        make.height.equalTo(@15);
    }];

    _stationNameLabel = [[UILabel alloc]init];
    _stationNameLabel.text = @"WS215i";
    _stationNameLabel.font = [UIFont boldSystemFontOfSize:16];
    _stationNameLabel.textColor = [UIColor whiteColor];
    _stationNameLabel.alpha = 0.87;
    [self.stationCardView addSubview:self.stationNameLabel];
    [_stationNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_stationLogoImageView.mas_right).offset(16);
        make.right.equalTo(_stationCardView.mas_right).offset(-16);
        make.bottom.equalTo(_stationTypeLabel.mas_top).offset(-3.5);
        make.height.equalTo(@20);
    }];
    
    _stationIpLabel = [[UILabel alloc]init];
    _stationIpLabel.text = @"10.10.10";
    _stationIpLabel.font = [UIFont systemFontOfSize:16];
    _stationIpLabel.textColor = [UIColor whiteColor];
    _stationIpLabel.alpha = 0.54;
    [self.stationCardView addSubview:self.stationIpLabel];
    [_stationIpLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_stationLogoImageView.mas_right).offset(16);
        make.right.equalTo(_stationCardView.mas_right).offset(-16);
        make.top.equalTo(_stationTypeLabel.mas_bottom).offset(2);
        make.height.equalTo(@15);
    }];
}

- (void)applicationWillResignActive:(NSNotification*)notification {
    _browser = nil;
    [self.userListTableViwe reloadData];
}

- (void) applicationDidBecomeActive:(NSNotification*)notification {
    [self beginSearching];
}

-(void)wechatLoginAction:(id)sender{
    
}

- (void)infoButtonClick:(UIButton *)sender{
    NSLog(@"点击了信息");
}

- (void)pageTurn:(UIPageControl *)pageControl{
//    NSInteger page = pageControl.currentPage;
    
  [_stationScrollView setContentOffset:CGPointMake(JYSCREEN_WIDTH * pageControl.currentPage, 0) animated:YES];

}

#pragma mark ScrollView delegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    int page = scrollView.contentOffset.x/CGRectGetWidth(self.view.frame);
    _stationPageControl.currentPage = page;
//    if (_stationPageControl.currentPage) {
//        _stationPageControl.transform=CGAffineTransformScale(CGAffineTransformIdentity, 2, 2);
//    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
}

#pragma mark tableView datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _dataSource.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 56;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    LoginTableViewCell *cell;
    self.userListTableViwe.separatorStyle = UITableViewCellSeparatorStyleNone;
    cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([LoginTableViewCell class])];
    if (!cell) {
        cell= [[[NSBundle mainBundle] loadNibNamed:@"LoginTableViewCell" owner:nil options:nil] lastObject];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    FMSerachService *ser ;
    ser.users = _dataSource;
    UserModel *userModel = ser.users[indexPath.row];
    cell.userNameLabel.text = userModel.username;
    
    return cell;
}

#pragma mark tableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    FMUserLoginViewController *userLoginVC = [[FMUserLoginViewController alloc]init];
    [self.navigationController pushViewController:userLoginVC animated:YES];
}

- (UIScrollView *)stationScrollView{
    if (!_stationScrollView) {
        _stationScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, JYSCREEN_WIDTH,448/2 + 64)];
        _stationScrollView.backgroundColor = UICOLOR_RGB(0x0288d1);
        _stationScrollView.pagingEnabled = YES;
//        _stationScrollView.contentSize = CGSizeMake(self.tempDataSource.count * JYSCREEN_WIDTH, 0);
        _stationScrollView.delegate = self;
        _stationScrollView.bounces = YES;
        _stationScrollView.showsHorizontalScrollIndicator = NO;
    }
    return _stationScrollView;
}

- (UIPageControl *)stationPageControl{
    if (!_stationPageControl) {
        _stationPageControl = [[StationPageControl alloc] initWithFrame:CGRectMake(0,self.stationScrollView.frame.size.height - 36 , JYSCREEN_WIDTH, 30)];
        _stationPageControl.numberOfPages = self.tempDataSource.count;
        _stationPageControl.currentPage = 0;
    }
    return _stationPageControl;
}

- (UIImageView *)logoImageView{
    if (!_logoImageView) {
        UIImage *logoImage = [UIImage imageNamed:@"logo"];
        CGSize logoSize=logoImage.size;
        _logoImageView = [[UIImageView alloc]initWithImage:logoImage];
        _logoImageView.frame = CGRectMake(16, 40, logoSize.width, logoSize.height);
    }
    return _logoImageView;
}

-(UIView *)userView{
    if (!_userView) {
        _userView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(self.stationScrollView.frame) + 8, JYSCREEN_WIDTH , 40)];
        _userView.backgroundColor = [UIColor whiteColor];
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(16, 0, JYSCREEN_WIDTH - 16, 40)];
        label.text = @"用户";
        label.font = [UIFont systemFontOfSize:14];
        label.textColor = [UIColor lightGrayColor];
        [_userView addSubview:label];
    }
    return _userView;
}

- (UITableView *)userListTableViwe{
    if (!_userListTableViwe) {
        _userListTableViwe = [[UITableView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(self.userView.frame), JYSCREEN_WIDTH, JYSCREEN_HEIGHT - _stationScrollView.frame.size.height - 8 - 48 - _userView.frame.size.height) style:UITableViewStylePlain];
        _userListTableViwe.delegate = self;
        _userListTableViwe.dataSource = self;
    }
    return _userListTableViwe;
}

- (UIView *)wechatView{
    if (!_wechatView) {
        _wechatView = [[UIView alloc]initWithFrame:CGRectMake(0, JYSCREEN_HEIGHT - 48, JYSCREEN_WIDTH, 48)];
        _wechatView.backgroundColor = [UIColor whiteColor];
        _wechatView.layer.shadowColor = [[UIColor blackColor]CGColor];
        _wechatView.layer.shadowOffset = CGSizeMake(0, 2);
        _wechatView.layer.shadowRadius = 2.0;
        _wechatView.layer.shadowOpacity = 0.4;
        _wechatView.userInteractionEnabled = YES;
        
        UIImage *wechatImage = [UIImage imageNamed:@"weChat"];
        UIImageView *wechatImageView = [[UIImageView alloc]initWithImage:wechatImage];
        [_wechatView addSubview:wechatImageView];
        [wechatImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_wechatView.mas_centerX).offset(-30);
            make.centerY.equalTo(_wechatView.mas_centerY);
            make.size.mas_equalTo(wechatImage.size);
        }];
        
        UILabel *label = [[UILabel alloc]init];
        label.text = @"微信登录";
        label.font = [UIFont systemFontOfSize:14];
        label.textColor = [UIColor blackColor];
        label.alpha = 0.87;
        [_wechatView addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(wechatImageView.mas_right).offset(8);
            make.centerY.equalTo(_wechatView.mas_centerY);
            make.size.mas_equalTo(CGSizeMake(100,20));
        }];
        
        UITapGestureRecognizer*tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(wechatLoginAction:)];
        [_wechatView addGestureRecognizer:tapGesture];
    }
    return _wechatView;
}

@end
