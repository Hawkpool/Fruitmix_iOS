//
//  FMLeftMenu.m
//  MenuDemo
//
//  Created by 杨勇 on 16/7/1.
//  Copyright © 2016年 Lying. All rights reserved.
//

#import "FMLeftMenu.h"
#import "FMLeftMenuCell.h"
#import "FMLeftUserCell.h"
#import "FMLeftUserFooterView.h"
#import "FMGetUserInfo.h"

@interface FMLeftMenu ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UILabel *versionLb;
@property (weak, nonatomic) IBOutlet UIButton *userBtn1;
@property (weak, nonatomic) IBOutlet UIButton *userBtn2;
@property (strong, nonatomic) FMUserLoginInfo *userInfo;
@property (strong, nonatomic) UIProgressView *backUpProgressView;
@property (strong, nonatomic) UILabel *progressLabel;
@end

@implementation FMLeftMenu


-(void)awakeFromNib{
    [super awakeFromNib];
//    self.userHeaderIV.layer.cornerRadius = self.userHeaderIV.frame.size.width/2;
//    self.userHeaderIV.backgroundColor = [UIColor blackColor];
    _settingTabelView.delegate = self;
    _settingTabelView.dataSource = self;
    
    _usersTableView.dataSource = self;
    _usersTableView.delegate = self;
    _isUserTableViewShow = NO;
    
    _settingTabelView.scrollEnabled = NO;
    _settingTabelView.tableFooterView = [UIView new];
    @weaky(self);
    _usersTableView.tableFooterView = [FMLeftUserFooterView footerViewWithTouchBlock:^{
        if(weak_self.delegate){
            [weak_self.delegate LeftMenuViewClickSettingTable:-1 andTitle:@"USER_FOOTERVIEW_CLICK"];
            [weak_self checkToStart];
        }
    }];

    _userBtn1.layer.cornerRadius = 20;
    _userBtn2.layer.cornerRadius = 20;
    
    self.userHeaderIV.userInteractionEnabled = YES;
    [self.userHeaderIV addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapHeader:)]];
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    // app名称
//    NSString *app_Name = [infoDictionary objectForKey:@"CFBundleName"];
    // app版本
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleVersion"];
    self.versionLb.text = [NSString stringWithFormat:@"WISNUC %@",app_Version];
   
    _progressLabel = [[UILabel alloc]init];
    _progressLabel.text = @"暂未连接服务器";
    _progressLabel.textColor = [UIColor colorWithRed:236 green:236 blue:236 alpha:1];
    _progressLabel.font = [UIFont fontWithName:@"Hiragino Sans GB" size:12];
    _progressLabel.textAlignment = NSTextAlignmentRight;
    _progressLabel.preferredMaxLayoutWidth = (self.frame.size.width -10.0 * 2);
    [_progressLabel  setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self addSubview:_progressLabel];
    [_progressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.mas_right).offset(-16);
        make.centerY.equalTo(_backupLabel.mas_centerY);
        make.height.equalTo(@40);
    }];
    
     _backUpProgressView = [[UIProgressView alloc]init];
    [self addSubview:_backUpProgressView];
    [_backUpProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_backupLabel.mas_right).offset(6);
        make.height.equalTo(@2);
        make.centerY.equalTo(_backupLabel.mas_centerY);
        make.right.equalTo(_progressLabel.mas_left).offset(-6);
    }];
}
- (IBAction)smallBtnClick:(id)sender {
    if (sender == _userBtn1) {
        [self.delegate LeftMenuViewClickUserTable:self.usersDatasource[_userBtn2.hidden?0:1]];
    }else{
        [self.delegate LeftMenuViewClickUserTable:self.usersDatasource[0]];
    }
}

-(void)setUsersDatasource:(NSMutableArray *)usersDatasource{
    _usersDatasource = usersDatasource;
    if (usersDatasource.count) {
        if (usersDatasource.count == 1) { //等于1
            _userBtn1.hidden = NO;
            _userBtn2.hidden = YES;
            [_userBtn1 setBackgroundImage:[UIImage imageForName:((FMUserLoginInfo *)usersDatasource[0]).userName size:_userBtn1.bounds.size] forState:UIControlStateNormal];
        }else{ // 大于 1
            _userBtn1.hidden = NO;
            _userBtn2.hidden = NO;
            [_userBtn1 setBackgroundImage:[UIImage imageForName:((FMUserLoginInfo *)usersDatasource[1]).userName size:_userBtn1.bounds.size] forState:UIControlStateNormal];
            [_userBtn2 setBackgroundImage:[UIImage imageForName:((FMUserLoginInfo *)usersDatasource[0]).userName size:_userBtn2.bounds.size] forState:UIControlStateNormal];
        }
    }else{
        _userBtn1.hidden = YES;
        _userBtn2.hidden = YES;
    }
}

-(void)checkToStart{
    if (_isUserTableViewShow) {
        [self dropDownBtnClick:_dropDownBtn];
    }
}


- (IBAction)dropDownBtnClick:(id)sender {
    _isUserTableViewShow = !_isUserTableViewShow;
    @weaky(self);
    if (_isUserTableViewShow) {
        ((UIButton *)sender).transform = CGAffineTransformMakeRotation(M_PI);
        [UIView animateWithDuration:0.3 animations:^{
            weak_self.usersTableView.alpha = 1;
            weak_self.userBtn1.alpha = 0;
            weak_self.userBtn2.alpha = 0;
//            self.usersDatasource = [NSMutableArray arrayWithArray:[FMDBControl getAllUserLoginInfo]];
            [weak_self.usersTableView reloadData];
        } completion:nil];
    }else{
        ((UIButton *)sender).transform = CGAffineTransformIdentity;
        NSMutableArray * tempArr = self.menus;
        self.menus = [NSMutableArray new];
        [_settingTabelView reloadData];
        self.menus = tempArr;
        [UIView animateWithDuration:0.3 animations:^{
            weak_self.usersTableView.alpha = 0;
            [weak_self.settingTabelView reloadData];
            weak_self.userBtn1.alpha = 1;
            weak_self.userBtn2.alpha = 1;
        } completion:^(BOOL finished) {
            NSMutableArray * tmpA = weak_self.usersDatasource;
            weak_self.usersDatasource = [NSMutableArray new];
            [weak_self.usersTableView reloadData];
            weak_self.usersDatasource = tmpA;
        }];
    }
}

- (void)tapHeader:(id)sender {
//    if(self.delegate){
//        [self.delegate LeftMenuViewClick:10 andTitle:@"个人信息"];
//    }
}

-(void)layoutSubviews{
    [super layoutSubviews];
    [self getUserInfo];
    self.nameLabel.font = [UIFont fontWithName:DONGQING size:14];
    FMUserLoginInfo * info = [FMDBControl findUserLoginInfo:DEF_UUID];
//    NSLog(@"%@",infox.bonjour_name);
    self.bonjourLabel.text = info.bonjour_name;
    NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
    [notiCenter addObserver:self selector:@selector(receiveNotification:) name:@"backUpProgressChange" object:nil];
    self.nameLabel.text = [FMConfigInstance getUserNameWithUUID:DEF_UUID];
    self.userHeaderIV.image = [UIImage imageForName:self.nameLabel.text size:self.userHeaderIV.bounds.size];
    
//===================================优雅的分割线/备份详情==========================================
    UILabel * progressLb = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, __kWidth, 15)];
    progressLb.font = [UIFont systemFontOfSize:12];
    progressLb.textAlignment = NSTextAlignmentCenter;
      dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [FMDBControl getDBAllLocalPhotosWithCompleteBlock:^(NSArray<FMLocalPhoto *> *result) {
        NSMutableArray * tmp = [NSMutableArray arrayWithCapacity:0];
        NSMutableArray *localPhotoHashArr = [NSMutableArray arrayWithCapacity:0];
        for (FMLocalPhoto * p in result) {
            [tmp addObject:p.localIdentifier];
            [localPhotoHashArr addObject:p.degist];
//            NSLog(@"%@",p.degist);
        }
        NSInteger allPhotos = result.count;
        FMDBSet * dbSet = [FMDBSet shared];
        FMDTSelectCommand * scmd  = FMDT_SELECT(dbSet.syncLogs);
        [scmd where:@"userId" equalTo:DEF_UUID];
        [scmd where:@"localId" containedIn:tmp];
        [scmd fetchArrayInBackground:^(NSArray *results) {
//            NSLog(@"%@",results);
            NSMutableArray *resultPhotoHashArr = [NSMutableArray arrayWithCapacity:0];
            for (FMSyncLogs *logs in results) {
//                NSLog(@"😑😑😑😑%@",logs.photoHash);
                [resultPhotoHashArr addObject:logs.photoHash];
            }
//            NSSet *resultSet = [NSSet setWithArray:resultPhotoHashArr];
//            NSArray * resultDataSource  = [resultSet allObjects];
//            NSSet *loacalSet = [NSSet setWithArray:localPhotoHashArr];
//            NSArray * localDataSource = [loacalSet allObjects];
            float progress = (float)results.count/(float)allPhotos;
//    NSLog(@"%f",progress);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.backupLabel.text = [NSString stringWithFormat:@"已备份%.f%%",progress * 100];
                self.backUpProgressView.progress = progress;
                
                self.progressLabel.text = [NSString stringWithFormat:@"%ld/%ld",(unsigned long)results.count,(long)allPhotos];

//                progressLb.text = [NSString stringWithFormat:@"本地照片总数: %ld张    已上传张数: %ld张",allPhotos,results.count];
            });
        }];

    }];
});
    
//    [cell.contentView addSubview:progressLb];
//    progressLb.hidden = !_displayProgress;
}


- (void)receiveNotification:(NSNotification *)noti
{
//    NSLog(@"%@ === %@ === %@", noti.object, noti.userInfo, noti.name);
//    NSString *currentImage = [noti.userInfo objectForKey:@"currentImage"];
//    NSString *allImage = [noti.userInfo objectForKey:@"allImage"];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        float progress = [currentImage floatValue]/[allImage floatValue];
//        NSLog(@"%f",progress);
//        self.backupLabel.text = [NSString stringWithFormat:@"已备份%.f%%",progress * 100];
//        self.backupProgressView.progress = progress;
//        self.progressLabel.text = [NSString stringWithFormat:@"%ld/%ld",[currentImage integerValue],[allImage integerValue]];
//        if ([currentImage integerValue]>0 &&[allImage integerValue]>0 && [currentImage integerValue] == [allImage integerValue]) {
//    
//        }
//    });

    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [FMDBControl getDBAllLocalPhotosWithCompleteBlock:^(NSArray<FMLocalPhoto *> *result) {
            NSMutableArray * tmp = [NSMutableArray arrayWithCapacity:0];
            for (FMLocalPhoto * p in result) {
                [tmp addObject:p.localIdentifier];
                //            NSLog(@"%@",p.degist);
            }
            NSInteger allPhotos = result.count;
            FMDBSet * dbSet = [FMDBSet shared];
            FMDTSelectCommand * scmd  = FMDT_SELECT(dbSet.syncLogs);
            [scmd where:@"userId" equalTo:DEF_UUID];
            [scmd where:@"localId" containedIn:tmp];
            [scmd fetchArrayInBackground:^(NSArray *results) {
                //            NSLog(@"%@",results);
                dispatch_async(dispatch_get_main_queue(), ^{
                    float progress = (float)results.count/(float)allPhotos;
                    //                NSLog(@"%lu",(unsigned long)results.count);
                    self.backupLabel.text = [NSString stringWithFormat:@"已备份%.f%%",progress * 100];
                    self.backUpProgressView.progress = progress;
                    self.progressLabel.text = [NSString stringWithFormat:@"%ld/%ld",(unsigned long)results.count,(long)allPhotos];
                    //                progressLb.text = [NSString stringWithFormat:@"本地照片总数: %ld张    已上传张数: %ld张",allPhotos,results.count];
                });
            }];
        }];
    
    });
   
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if(tableView == _settingTabelView)
        return 2;
    else
        return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(tableView == _settingTabelView){
        if (section == 0) {
            return 1;
        }
        return self.menus.count - 1;
    }else
        return self.usersDatasource.count;
    
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == _settingTabelView) {
        FMLeftMenuCell *cell = [[[NSBundle mainBundle] loadNibNamed:@"FMLeftMenuCell" owner:nil options:nil] lastObject];
        if (indexPath.section == 0) {
            cell.leftLine.backgroundColor = [UIColor blackColor];
            [cell setData:_menus[indexPath.row] andImageName:_imageNames[indexPath.row]];
        }else{
            [cell setData:_menus[indexPath.row + 1] andImageName:_imageNames[indexPath.row + 1]];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }else{
        FMLeftUserCell * cell =  [[[NSBundle mainBundle] loadNibNamed:@"FMLeftUserCell" owner:nil options:nil] lastObject];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        FMUserLoginInfo * info =  self.usersDatasource[indexPath.row];
        cell.userNameLb.text = info.userName;
        cell.deviceNameLb.text = info.bonjour_name;
        cell.userHeader.image = [UIImage imageForName:info.userName size:cell.userHeader.bounds.size];
        return cell;
    }
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(tableView == _settingTabelView){
        if(self.delegate){
            [self.delegate LeftMenuViewClickSettingTable:indexPath.section == 0? indexPath.row:indexPath.row+1 andTitle:indexPath.section == 0? self.menus[indexPath.row]:self.menus[indexPath.row+1]];
        }
    }else{
        if(self.delegate){
            [self.delegate LeftMenuViewClickUserTable:self.usersDatasource[indexPath.row]];
            [self checkToStart];
        }
    }
    
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return [UIView new];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 1) {
        return 8;
    }
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(tableView == _settingTabelView){
        if(indexPath.section == 0 )
            return 72;
        return  [FMLeftMenuCell height];
    }else{
        return [FMLeftUserCell height];
    }
    
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    double delay = (indexPath.row*indexPath.row) * 0.004;  //Quadratic time function for progressive delay
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(0.95, 0.95);
    CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(0,(tableView == _settingTabelView?1:-1)*(indexPath.row+1)*CGRectGetHeight(cell.contentView.frame));
    cell.transform = CGAffineTransformConcat(scaleTransform, translationTransform);
    cell.alpha = 0.f;
    
    [UIView animateWithDuration:0.6/2 delay:delay options:UIViewAnimationOptionCurveEaseOut animations:^
     {
         cell.transform = CGAffineTransformIdentity;
         cell.alpha = 1.f;
         
     } completion:nil];
}

- (void)getUserInfo{
    NSMutableArray * arr = [FMGetUserInfo getUsersInfo];
    for (FMUserLoginInfo * info in arr) {
        _userInfo = info;
    }
}

- (void)dealloc
{
    // 移除当前对象监听的事件
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UILabel *)backupLabel{
    if (!_backupLabel) {
        
    }
    return _backupLabel;
}
@end
