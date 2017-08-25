//
//  FLDownloadManager.m
//  FruitMix
//
//  Created by 杨勇 on 16/10/11.
//  Copyright © 2016年 WinSun. All rights reserved.
//

#import "FLDownloadManager.h"
#import "FLDownload.h"

@interface FLDownloadManager ()<TYDownloadDelegate>

@end

@implementation FLDownloadManager

+(instancetype)shareManager{
    static FLDownloadManager * manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[FLDownloadManager alloc]init];
        [TYDownLoadDataManager manager].delegate = manager;
    });
    return manager;
}

-(void)downloadFileWithFileModel:(FLFilesModel *)model parentUUID:(NSString *)uuid{
    NSLog(@"%@",[JYRequestConfig sharedConfig].baseURL);
    NSString * filePath = [NSString stringWithFormat:@"%@/%@",File_DownLoad_DIR,model.name];
    NSString * exestr = [filePath lastPathComponent];
    NSString *urlString = [NSString stringWithFormat:@"%@drives/%@/dirs/%@/entries/%@?name=%@",[JYRequestConfig sharedConfig].baseURL,DRIVE_UUID,uuid,model.uuid,exestr];
    NSString *encodedString = [urlString URLEncodedString];
       TYDownloadModel * downloadModel = [[TYDownloadModel alloc] initWithURLString:encodedString filePath:filePath];

    downloadModel.jy_fileName = model.name;
    TYDownLoadDataManager *manager = [TYDownLoadDataManager manager];
    [manager startWithDownloadModel:downloadModel];
    [[NSNotificationCenter defaultCenter] postNotificationName:FLDownloadFileChangeNotify object:nil];
}

-(void)downloadModel:(TYDownloadModel *)downloadModel didChangeState:(TYDownloadState)state filePath:(NSString *)filePath error:(NSError *)error{
    
    if(state == TYDownloadStateCompleted || state == TYDownloadStateNone){
        [[NSNotificationCenter defaultCenter] postNotificationName:FLDownloadFileChangeNotify object:nil];
        if (state == TYDownloadStateCompleted) {
            FLDownload * download = [FLDownload new];
            download.name = downloadModel.jy_fileName;
            NSLog(@"%@",download.name);
            NSDateFormatter * formatter1 = [[NSDateFormatter alloc]init];
            formatter1.dateFormat = @"yyyy-MM-dd hh:mm:ss";
            [formatter1 setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
            NSString * dateString = [formatter1 stringFromDate:[NSDate date]];
            download.downloadtime = dateString;
            download.uuid = downloadModel.fileName;
            download.userId = FMConfigInstance.userUUID;
            [FMDBControl updateDownloadWithFile:download isAdd:YES];
        }
    }
}
- (void)cancleWithDownloadModel:(TYDownloadModel *)downloadModel{
      TYDownLoadDataManager *manager = [TYDownLoadDataManager manager];
      [manager cancleWithDownloadModel:downloadModel];
}

-(void)downloadModel:(TYDownloadModel *)downloadModel didUpdateProgress:(TYDownloadProgress *)progress{
    
}
@end
