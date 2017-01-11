//
//  AppDelegate.m
//  FruitMix
//
//  Created by JackYang on 16/3/15.
//  Copyright © 2016年 WinSun. All rights reserved.
//

#import "AppDelegate.h"

#import "NavViewController.h"
#import "FMShareViewController.h"
#import "FMAlbumsViewController.h"
#import "FMPhotosViewController.h"
#import "RDVTabBarItem.h"

#import "FMInfo.h"
#import "FMUserEditVC.h"
#import "FMHelp.h"
#import "FMSetting.h"
#import "FMOwnCloud.h"
#import "FMUserSetting.h"
#import "BackgroundRunner.h"

#import "RRFPSBar.h"
#import "FLFilesVC.h"
#import "FLShareVC.h"
#import "FLLocalFIleVC.h"

#import <CoreTelephony/CTCellularData.h>
#import "UIApplication+JYTopVC.h"

#import <CocoaLumberjack/CocoaLumberjack.h>

// Log levels: off, error, warn, info, verbose
//static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface AppDelegate ()<UIAlertViewDelegate,FMLeftMenuDelegate>

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
//    [[RRFPSBar sharedInstance]setHidden:YES];
//    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    //配置侧拉
    [self initLeftMenu];
    //配置app的模式
    [self configAppMode];
    //检测奔溃
    [self checkExceptions];
    //配置主视图
    [self configRootWindow];
    [self configNotify];
    //配置 行为统计 /检测网络权限
    [self configUmeng];
    
    return YES;
}

-(BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    //更新图库
    [FMDBControl asyncLoadPhotoToDB];
    return YES;
}


#pragma mark - Background Upload


- (void)applicationDidEnterBackground:(UIApplication *)application {

    self.isBackground = YES;
//    [[BackgroundRunner shared] run];
    if (self.didEnterBackgroundHandler) {
        self.didEnterBackgroundHandler();
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
//    [[BackgroundRunner shared] stop];
    self.isBackground = NO;
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    self.backgroundSessionCompletionHandler = completionHandler;
}


/***********************************************************/
/********************* Some Config *************************/
/***********************************************************/

-(void)configRootWindow{
    if (!IsNilString(DEF_Token)) {
        NSLog(@"UserToken : %@",DEF_Token);
        NSLog(@"Last Connect IP : %@",BASE_URL);
        
        self.sharesTabBar = [[RDVTabBarController alloc]init];
        [self initWithTabBar:self.sharesTabBar];
        self.window.rootViewController = self.sharesTabBar;
        [self.window makeKeyAndVisible];
    }else{
        NSLog(@"上次未登录, 重新登录");
        
        FMLoginVC * vc = [[FMLoginVC alloc]init];
        vc.title = @"搜索附近设备";
        NavViewController *nav = [[NavViewController alloc] initWithRootViewController:vc];
        self.window.rootViewController = nav;
        [self.window makeKeyAndVisible];
    }
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent];
}

// CocoaLumberjack
//-(void)configAppLog{
//    [DDLog addLogger:[DDASLLogger sharedInstance]];
//    [DDLog addLogger:[DDTTYLogger sharedInstance]];
//    DDFileLogger * fileLogger = [[DDFileLogger alloc] init];
//    fileLogger.rollingFrequency = 60 * 60 * 24*7; // 24 hour rolling
//    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
//    [DDLog addLogger:fileLogger];
//}


//配置app的模式
-(void)configAppMode{
//默认配置为YES
    
    FMConfigInstance.isDebug = NO;
    FMConfigInstance.shouldUpload = NO;
    UIDevice *device = [UIDevice currentDevice];
    
//    NSLog(@"手机名称：%@",device.name);
    if (![[device name] isEqualToString:@"iPhone Simulator"] && ![device.name containsString:@"JackYang"]) {
//         开始保存日志文件
//        [self redirectNSlogToDocumentFolder];
        [FMConfiguation shareConfiguation].shouldUpload = NO;
    }
}


//检查奔溃信息
-(void)checkExceptions{
    if (EXCEPTION_HANDLER) {
    }
}

-(void)resetDatasource{
    //重置侧拉数据
    [[NSNotificationCenter defaultCenter]postNotificationName:FM_USER_ISADMIN object:@(0)];
    //重置数据源
    self.photoDatasource = nil;
    self.mediaDataSource = nil;
}

//配置侧拉
-(void)initLeftMenu{
    FMLeftMenu * leftMenu = [[[NSBundle mainBundle]loadNibNamed:@"FMLeftMenu" owner:nil options:nil]lastObject];
    leftMenu.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width * 0.8, [[UIScreen mainScreen] bounds].size.height);
    _leftMenu = leftMenu;
    leftMenu.delegate = self;
    leftMenu.menus = [NSMutableArray arrayWithObjects:@"我的文件",@"设置",@"注销",nil];//@"个人信息", @"我的私有云", @"用户管理", @"设置", @"帮助",
    leftMenu.imageNames = [NSMutableArray arrayWithObjects:@"files",@"set",@"cancel",nil];//@"personal",@"cloud",@"user",@"set",@"help",
    [leftMenu.settingTabelView reloadData];
    _Info = [[FMUserEditVC alloc]init];
    _OwnCloud = [[FMOwnCloud alloc]init];
    _UserSetting = [[FMUserSetting alloc]init];
    _Setting = [[FMSetting alloc]init];
    _Help = [[FMHelp alloc]init];
    _zhuxiao = [[FMLoginVC alloc]init];
    self.menu = [MenuView MenuViewWithDependencyView:self.window MenuView:leftMenu isShowCoverView:YES];
    self.menu.showBlock = ^() {
        UIViewController * topVC = [UIApplication topViewController];
        if([topVC isKindOfClass:[RTContainerController class]])
            topVC = ((RTContainerController *)topVC).contentViewController;
        if ([topVC isKindOfClass:[FLBaseVC class]] || [topVC isKindOfClass:[FMBaseFirstVC class]]) {
            return YES;
        }
        return NO;
    };
}

-(void)reloadLeftMenuIsAdmin:(BOOL)isAdmin{
    NSMutableArray * menusTitle = nil;
    NSMutableArray * menusImages = nil;
    if (!isAdmin){
        menusTitle =  [NSMutableArray arrayWithObjects:@"我的文件",@"设置",@"注销", nil];//,@"个人信息",@"personal"
        menusImages = [NSMutableArray arrayWithObjects:@"files",@"set",@"cancel",nil];
    }else{
        menusTitle = [NSMutableArray arrayWithObjects:@"我的文件",@"用户管理",@"设置",@"注销",nil];//,@"个人信息",@"personal"
        menusImages = [NSMutableArray arrayWithObjects:@"files",@"person_add",@"set",@"cancel",nil];
    }
    
    _leftMenu.menus = menusTitle;
    _leftMenu.imageNames = menusImages;
    [_leftMenu.settingTabelView reloadData];
}


// 将NSlog打印信息保存到Document目录下的文件中
- (void)redirectNSlogToDocumentFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"winsun.log"];// 注意不是NSData!
    NSString *logFilePath = [documentDirectory stringByAppendingPathComponent:fileName];
    // 先删除已经存在的文件
//    NSFileManager *defaultManager = [NSFileManager defaultManager];
//    [defaultManager removeItemAtPath:logFilePath error:nil];
    
    // 将log输入到文件
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
}



-(void)initWithTabBar:(RDVTabBarController *)tabbar{
    /* 页面 */
    FMShareViewController * shareVC = [[FMShareViewController alloc]init];
    FMPhotosViewController * photosVC = [[FMPhotosViewController alloc]init];
    FMAlbumsViewController * albumsVC = [[FMAlbumsViewController alloc]init];
    /* 导航 */
    NavViewController *nav0 = [[NavViewController alloc] initWithRootViewController:shareVC];
    
    NavViewController *nav1 = [[NavViewController alloc]initWithRootViewController:photosVC];
    NavViewController *nav2 = [[NavViewController alloc] initWithRootViewController:albumsVC];
    
    shareVC.title = @"分享";
    photosVC.title = @"照片";
    albumsVC.title = @"相册";
    NSMutableArray *viewControllersMutArr = [[NSMutableArray alloc] initWithObjects:nav0, nav1,nav2,nil];
    [tabbar setViewControllers:viewControllersMutArr];
    tabbar.tabBar.backgroundView.backgroundColor = UICOLOR_RGB(0x3f51b5);
    NSArray *tabBarItemImages = @[@"share", @"photo", @"photo-album"];
    NSInteger index = 0;
    for (RDVTabBarItem *item in [[tabbar tabBar] items]) {
        UIImage *selectedimage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_select",
                                                      [tabBarItemImages objectAtIndex:index]]];
        UIImage *unselectedimage = [UIImage imageNamed:[NSString stringWithFormat:@"%@",
                                                        [tabBarItemImages objectAtIndex:index]]];
        item.title = @"";
        [item setFinishedSelectedImage:selectedimage withFinishedUnselectedImage:unselectedimage];
        index++;
    }
    tabbar.selectedIndex = 0;
}


-(RDVTabBarController *)filesTabBar{
    if (!_filesTabBar) {
        _filesTabBar = [[RDVTabBarController alloc]init];
        [self initFilesWithTabBar:_filesTabBar];
    }
    return _filesTabBar;
}

-(void)initFilesWithTabBar:(RDVTabBarController *)tabbar{
    /* 页面 */
    FLFilesVC * filesVC = [[FLFilesVC alloc]init];
    FLShareVC * shareVC = [[FLShareVC alloc]init];
    FLLocalFIleVC * localFilesVC = [[FLLocalFIleVC alloc]init];
    /* 导航 */
    NavViewController *nav0 = [[NavViewController alloc] initWithRootViewController:shareVC];
    
    NavViewController *nav1 = [[NavViewController alloc]initWithRootViewController:filesVC];
    NavViewController *nav2 = [[NavViewController alloc] initWithRootViewController:localFilesVC];
    
    shareVC.title = @"分享";
    filesVC.title = @"文件";
    localFilesVC.title = @"本地";
    NSMutableArray *viewControllersMutArr = [[NSMutableArray alloc] initWithObjects:nav0, nav1,nav2,nil];
    [tabbar setViewControllers:viewControllersMutArr];
    tabbar.tabBar.backgroundView.backgroundColor = UICOLOR_RGB(0x3f51b5);
    NSArray *tabBarItemImages = @[@"share", @"hard", @"local"];
    NSInteger index = 0;
    for (RDVTabBarItem *item in [[tabbar tabBar] items]) {
        UIImage *selectedimage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_select",
                                                      [tabBarItemImages objectAtIndex:index]]];
        UIImage *unselectedimage = [UIImage imageNamed:[NSString stringWithFormat:@"%@",
                                                        [tabBarItemImages objectAtIndex:index]]];
        item.title = @"";
        [item setFinishedSelectedImage:selectedimage withFinishedUnselectedImage:unselectedimage];
        index++;
    }
    tabbar.selectedIndex = 0;
}

-(void)_hiddenMenu{
    if (self.menu) {
        [self.menu hidenWithAnimation];
    }
}


-(void)applicationDidBecomeActive:(UIApplication *)application{
//    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

#pragma mark - leftmenu Delegate

-(void)LeftMenuViewClick:(NSInteger)tag andTitle:(NSString *)title{
    [self _hiddenMenu];
    UIViewController * vc = nil;
    RDVTabBarController * tVC = (RDVTabBarController *)self.window.rootViewController;
    NavViewController * selectVC = (NavViewController *)tVC.selectedViewController;
    if(IsEquallString(title, @"个人信息")){
        vc = self.Info;
        if ([selectVC isKindOfClass:[NavViewController class]]) {
            [selectVC  pushViewController:vc animated:YES];
        }
    }else if(IsEquallString(title, @"用户管理")){
        vc = self.UserSetting;
        if ([selectVC isKindOfClass:[NavViewController class]]) {
            [selectVC  pushViewController:vc animated:YES];
        }
    }
    else if (IsEquallString(title, @"我的照片")){
        self.window.rootViewController = self.sharesTabBar;
        [self.window makeKeyAndVisible];
        NSInteger index = [self.leftMenu.menus indexOfObject:@"我的照片"];
        self.leftMenu.menus[index] = @"我的文件";
        self.leftMenu.imageNames[index] = @"files";
        [self.leftMenu.settingTabelView reloadData];
    }else if (IsEquallString(title, @"我的文件")){
        self.window.rootViewController = self.filesTabBar;
        [self.window makeKeyAndVisible];
        NSInteger index = [self.leftMenu.menus indexOfObject:@"我的文件"];
        self.leftMenu.menus[index] = @"我的照片";
        self.leftMenu.imageNames[index] = @"photos";
        [self.leftMenu.settingTabelView reloadData];
    }
    else if (IsEquallString(title, @"设置")){
            vc = self.Setting;
            if ([selectVC isKindOfClass:[NavViewController class]]) {
                [selectVC  pushViewController:vc animated:YES];
            }
        }
    else if(IsEquallString(title,@"注销")){
        vc = self.zhuxiao;
        [SXLoadingView showProgressHUD:@"正在注销"];
        [PhotoManager shareManager].canUpload = NO;//停止上传
        FMConfigInstance.userToken = @"";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SXLoadingView hideProgressHUD];
            FMLoginVC * vc = [[FMLoginVC alloc]init];
            vc.title = @"搜索附近设备";
            NavViewController *nav = [[NavViewController alloc] initWithRootViewController:vc];
            self.window.rootViewController = nav;
            [self.window makeKeyAndVisible];
        });
    }
}

-(void)configUmeng{
    if(kSystemVersion>9.0){
        CTCellularData *cellularData = [[CTCellularData alloc]init];
        CTCellularDataRestrictedState state = cellularData.restrictedState;
        switch (state) {
            case kCTCellularDataRestricted:
                NSLog(@"Restricrted");
                break;
            case kCTCellularDataNotRestricted:
                NSLog(@"Not Restricted");
                break;
            case kCTCellularDataRestrictedStateUnknown:
                NSLog(@"Unknown");
                break;
            default:
                break;
        }
    }
}

-(void)configNotify{
    _notification = [CWStatusBarNotification new];
    _notification.notificationLabelBackgroundColor = StatusBar_Color;
    _notification.notificationLabelFont = [UIFont fontWithName:FANGZHENG size:13.5f];
    _notification.notificationAnimationInStyle = CWNotificationAnimationStyleTop;
    _notification.notificationAnimationOutStyle = CWNotificationAnimationStyleBottom;
    _notification.notificationStyle = CWNotificationStyleNavigationBarNotification;
    
    _statusBarNotification = [CWStatusBarNotification new];
    _statusBarNotification.notificationLabelBackgroundColor = StatusBar_Color;
    _statusBarNotification.notificationLabelFont = [UIFont fontWithName:FANGZHENG size:5.0f];
    _statusBarNotification.notificationAnimationInStyle = CWNotificationAnimationStyleTop;
    _statusBarNotification.notificationAnimationOutStyle = CWNotificationAnimationStyleBottom;
    _statusBarNotification.notificationStyle = CWNotificationStyleStatusBarNotification;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleChangeIsAdminNotify:) name:FM_USER_ISADMIN object:nil];
}

-(void)handleChangeIsAdminNotify:(NSNotification *)notify{
    BOOL isAdmin = [notify.object boolValue];
    [self reloadLeftMenuIsAdmin:isAdmin];
}

#pragma mark - Initial Data

-(UIView *)notifyViewWithMessage:(NSString *)message{
    UIView * view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, __kWidth, 20)];
    UILabel * label = [[UILabel alloc]initWithFrame:view.bounds];
    [view addSubview:label];
    label.font = [UIFont fontWithName:FANGZHENG size:8];
    label.textAlignment = NSTextAlignmentCenter;
    view.backgroundColor = StatusBar_Color;
    label.backgroundColor = StatusBar_Color;
    return view;
}

@end