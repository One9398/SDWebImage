//
//  UIImageView+HighlightedWebCache.h
//  SDWebImage Demo
//
//  Created by Simon on 8/23/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ONEWebImageCompat.h"
#import "ONEWebImageManager.h"

@interface UIImageView (ONEHighlightedWebCache)

- (void)one_setHighlightedImageWithURL:(NSURL *)url;

- (void)one_setHighlightedImageWithURL:(NSURL *)url options:(ONEWebImageOptions)options;

- (void)one_setHighlightedImageWithURL:(NSURL *)url completed:(ONEWebImageDownloaderCompletedBlock)completedBlock;

- (void)one_setHighlightedImageWithURL:(NSURL *)url options:(ONEWebImageOptions)options completed:(ONEWebImageDownloaderCompletedBlock)completedBlock;

- (void)one_setHighlightedImageWithURL:(NSURL *)url options:(ONEWebImageOptions)options progress:(ONEWebImageDownloaderProgressBlock)progressBlock completed:(ONEWebImageDownloaderCompletedBlock)completedBlock;

@end
