
//
//  FMPhotoDataSource.m
//  FruitMix
//
//  Created by 杨勇 on 16/8/24.
//  Copyright © 2016年 WinSun. All rights reserved.
//

#import "FMPhotoDataSource.h"

@implementation FMPhotoDataSource{
    NSMutableArray * _photosLocalIds;
    NSMutableArray * _localphotoDigest;
}

+(instancetype)shareInstance{
    //不能使用 单例 姑且挂到 appdelegate 上
    if(!MyAppDelegate.photoDatasource){
        MyAppDelegate.photoDatasource = [FMPhotoDataSource new];
    }
    return MyAppDelegate.photoDatasource;
}

-(void)dealloc{
    
}

-(instancetype)init{
    if (self = [super init]) {
        self.imageArr = [NSMutableArray arrayWithCapacity:0];
        self.timeArr = [NSMutableArray arrayWithCapacity:0];
        self.dataSource = [NSMutableArray arrayWithCapacity:0];
        _photosLocalIds = [NSMutableArray arrayWithCapacity:0];
        _localphotoDigest = [NSMutableArray arrayWithCapacity:0];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLibruaryChange) name:PHOTO_LIBRUARY_CHANGE_NOTIFY object:nil];
        [self initPhotos];
    }
    return self;
}

-(void)handleLibruaryChange{
    [self initPhotosIsRefrash];
}

-(void)initPhotos{
//    PHFetchOptions * option = [[PHFetchOptions alloc]init];
//    option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    [FMDBControl getDBPhotosWithCompleteBlock:^(NSArray<FMLocalPhoto *> *result){
        NSMutableArray * arr = [NSMutableArray arrayWithCapacity:0];
        for (FMLocalPhoto * photo in result) {
            [_photosLocalIds addObject:photo.localIdentifier];//记录本地图的ids
             FMPhotoAsset * asset = [FMPhotoAsset new];
             asset.localId = photo.localIdentifier;
             asset.degist = photo.degist;
             asset.createtime = photo.createDate;
            if (asset.degist.length)
                [_localphotoDigest addObject:asset.degist];
             [arr addObject:asset];
        }
        self.imageArr = arr;
        [self sequencePhotosAndCompleteBlock:^{
            //搜索网络数据
            [self getNetPhotos];
        }];
    }];
}

-(void)getNetPhotos{
    NSLog(@"当前 UUID: %@ ",DEF_UUID);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        FMMediaAPI * api = [FMMediaAPI new];
        [api startWithCompletionBlockWithSuccess:^(__kindof JYBaseRequest *request) {
            [self analysisPhotos:request.responseJsonObject];
        } failure:^(__kindof JYBaseRequest *request) {
            NSLog(@"载入Media失败,%@",request.error);
        }];
    });
}

-(void)analysisPhotos:(id)response{
    NSArray * userArr = response;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray * photoArr = [NSMutableArray arrayWithCapacity:0];
        for (NSDictionary * dic in userArr) {
            FMNASPhoto * nasPhoto = [FMNASPhoto yy_modelWithJSON:dic];
            if(!IsNilString([nasPhoto getPhotoHash]) && ![_localphotoDigest containsObject:[nasPhoto getPhotoHash]])
                [photoArr addObject:nasPhoto];
        }
        NSLog(@"******************     网络来图      *****************************");
        NSLog(@"%@",photoArr);
        NSLog(@"******************  网络来图打印完成  *****************************");
        if (photoArr.count) {
            self.netphotoArr = [photoArr copy];
            [_imageArr addObjectsFromArray:photoArr];
            [self initPhotosIsRefrash];
        }
    });
    //Cache 到数据库
//    [FMDBControl asynNASPhoto:[photoArr copy] andCompleteBlock:^{
//        NSLog(@"cache nasPhoto 数据完成");
//    }];
}

-(void)initPhotosIsRefrash{
    @weakify(self);
    [FMDBControl getDBPhotosWithCompleteBlock:^(NSArray<FMLocalPhoto *> *result) {
        NSMutableArray * arr = [NSMutableArray arrayWithCapacity:0];
        for (FMLocalPhoto * photo in result) {
            if(![_photosLocalIds containsObject:photo.localIdentifier]){
                [_photosLocalIds addObject:photo.localIdentifier];//记录本地图的ids
                FMPhotoAsset * asset = [FMPhotoAsset new];
                asset.localId = photo.localIdentifier;
                asset.degist = photo.degist;
                asset.createtime = photo.createDate;
                [arr addObject:asset];
            }
        }
        [weak_self.imageArr addObjectsFromArray: arr];
        [weak_self sequencePhotosAndCompleteBlock:nil];
    }];
}

-(void)sequencePhotosAndCompleteBlock:(void(^)())block{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSComparator cmptr = ^(IDMPhoto * photo1, IDMPhoto * photo2){
            NSDate * tempDate = [[photo1 getPhotoCreateTime]laterDate:[photo2 getPhotoCreateTime]];
            if ([tempDate isEqualToDate:[photo1 getPhotoCreateTime]]) {
                return (NSComparisonResult)NSOrderedAscending;
            }
            if ([tempDate isEqualToDate:[photo2 getPhotoCreateTime]]) {
                return (NSComparisonResult)NSOrderedDescending;
            }
            return (NSComparisonResult)NSOrderedSame;
        };
        [self.imageArr sortUsingComparator:cmptr];
        [self getTimeArrAndPhotoGroupArrWithCompleteBlock:^(NSMutableArray *tGroup, NSMutableArray *pGroup) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _timeArr = tGroup;
                _dataSource = pGroup;
                //
                _isFinishLoading = YES;
                NSLog(@"\n\n*******************排序完成 ********************\n\n");
                NSLog(@"%@",_dataSource);
                NSLog(@"***********************打印结束**************************\n\n");
                [[NSNotificationCenter defaultCenter]postNotificationName:FMPhotoDatasourceLoadFinishNotify object:nil];
                if (block) block();
                if (_delegate && [_delegate respondsToSelector:@selector(dataSourceFinishToLoadPhotos)]) {
                    [_delegate dataSourceFinishToLoadPhotos];
                }
            });
        }];
    });
}

-(void)getTimeArrAndPhotoGroupArrWithCompleteBlock:(SortSuccessBlock)block{
    NSMutableArray * tArr = [NSMutableArray array];//时间组
    NSMutableArray * pGroupArr = [NSMutableArray array];//照片组数组
    if (self.imageArr.count>0) {
        IDMPhoto * photo = self.imageArr[0];
        NSMutableArray * photoDateGroup1 = [NSMutableArray array];//第一组照片
        [photoDateGroup1 addObject:photo];
        [pGroupArr addObject:photoDateGroup1];
        [tArr addObject:[photo getPhotoCreateTime]];
        
        NSMutableArray * photoDateGroup2 = photoDateGroup1;//最近的一组
        for (int i = 1 ; i < self.imageArr.count; i++) {
            IDMPhoto * photo1 =  self.imageArr[i];
            IDMPhoto * photo2 = self.imageArr[i-1];
            if ([self isSameDay:[photo1 getPhotoCreateTime] date2:[photo2 getPhotoCreateTime]]) {
                [photoDateGroup2 addObject:photo1];
            }
            else{
                [tArr addObject:[photo1 getPhotoCreateTime]];
                photoDateGroup2 = nil;
                photoDateGroup2 = [NSMutableArray array];
                [photoDateGroup2 addObject:photo1];
                [pGroupArr addObject:photoDateGroup2];
            }
        }
    }
    //主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        block(tArr,pGroupArr);
    });
}

- (BOOL)isSameDay:(NSDate *)date1 date2:(NSDate *)date2

{
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlag = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    
    NSDateComponents *comp1 = [calendar components:unitFlag fromDate:date1];
    
    NSDateComponents *comp2 = [calendar components:unitFlag fromDate:date2];
    
    return (([comp1 day] == [comp2 day]) && ([comp1 month] == [comp2 month]) && ([comp1 year] == [comp2 year]));
    
}

-(NSString *)getDateStringWithPhoto:(NSDate *)date{
    NSDateFormatter * formatter1 = [[NSDateFormatter alloc]init];
    formatter1.dateFormat = @"yyyy-MM-dd";
    [formatter1 setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSString * dateString = [formatter1 stringFromDate:date];
    return dateString;
}
@end
