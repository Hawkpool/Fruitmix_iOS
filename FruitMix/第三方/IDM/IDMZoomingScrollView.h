//
//  IDMZoomingScrollView.h
//  IDMPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDMPhotoProtocol.h"
#import "IDMTapDetectingImageView.h"
#import "IDMTapDetectingView.h"

#import <DACircularProgress/DACircularProgressView.h>

typedef enum : NSUInteger {
    JYPhotoCanChoose,
    JYPhotoNormal,
} JYPhotoState;

@class IDMPhotoBrowser, IDMPhoto, IDMCaptionView;

@interface IDMZoomingScrollView : UIScrollView <UIScrollViewDelegate, IDMTapDetectingImageViewDelegate, IDMTapDetectingViewDelegate> {
	
	IDMPhotoBrowser *__weak _photoBrowser;
    id<IDMPhoto> _photo;
	
    // This view references the related caption view for simplified handling in photo browser
    IDMCaptionView *_captionView;
    
	IDMTapDetectingView *_tapView; // for background taps
    
    DACircularProgressView *_progressView;
}

@property (nonatomic, strong) IDMTapDetectingImageView *photoImageView;
@property (nonatomic, strong) IDMCaptionView *captionView;
@property (nonatomic, strong) id<IDMPhoto> photo;
@property (nonatomic) CGFloat maximumDoubleTapZoomScale;

//jy
@property (nonatomic) UIButton * chooseBtn;
@property (nonatomic) UIImageView * lockIV;
@property (nonatomic) JYPhotoState photoState;
@property (nonatomic) BOOL isChoose;


- (id)initWithPhotoBrowser:(IDMPhotoBrowser *)browser;
- (void)displayImage;
- (void)displayImageFailure;
- (void)setProgress:(CGFloat)progress forPhoto:(IDMPhoto*)photo;
- (void)setMaxMinZoomScalesForCurrentBounds;
- (void)prepareForReuse;

@end
