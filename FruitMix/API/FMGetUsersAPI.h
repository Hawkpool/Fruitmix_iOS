//
//  FMGetUsersAPI.h
//  FruitMix
//
//  Created by 杨勇 on 16/4/20.
//  Copyright © 2016年 WinSun. All rights reserved.
//

#import "JYBaseRequest.h"

@interface FMGetUsersAPI : JYBaseRequest<JYRequestDelegate>
+ (instancetype)apiWithStationId:(NSString *)stationId;
@property (nonatomic,strong)NSString *stationId;
@end
