//
//  FLDownloadingCell.h
//  FruitMix
//
//  Created by 杨勇 on 16/10/11.
//  Copyright © 2016年 WinSun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLDownloadingCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *fileImageView;
@property (weak, nonatomic) IBOutlet UILabel *filenameLb;
@property (weak, nonatomic) IBOutlet UILabel *downloadProgressLb;

@end
