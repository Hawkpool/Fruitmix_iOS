//
//  FMDBSet.h
//  FruitMix
//
//  Created by 杨勇 on 16/4/21.
//  Copyright © 2016年 WinSun. All rights reserved.
//

#import "FMDTManager.h"

#import "FMLocalPhoto.h"
#import "FMNASPhoto.h"
#import "FMMediaShare.h"
#import "FMUsers.h"
#import "FMOwnerSet.h"
#import "FLDownload.h"

#import "FMNeedQuickUploadPhoto.h"
#import "FMNeedUploadMediaShare.h"
#import "FMNeedUploadComments.h"
#import "FMNeedUploadPatch.h"
#import "FMUserInfo.h"


@interface FMDBSet : FMDTManager

@property (nonatomic)BOOL isLoading;

@property (nonatomic) FMDTContext * photo;

@property (nonatomic) FMDTContext * nasPhoto;

@property (nonatomic) FMDTContext * mediashare;

@property (nonatomic) FMDTContext * users;

@property (nonatomic) FMDTContext * ownerset;

@property (nonatomic) FMDTContext * download;//文件下载

@property (nonatomic) FMDTContext * needUploadPatch;

@property (nonatomic) FMDTContext * needQuickUploadPhoto;

@property (nonatomic) FMDTContext * needUploadMediaShare;

@property (nonatomic) FMDTContext * needUploadComments;

@property (nonatomic) FMDTContext * userInfo;

@end
