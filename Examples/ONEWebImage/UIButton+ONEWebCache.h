//
//  UIButton+ONEWebCache.h
//  SDWebImage Demo
//
//  Created by Simon on 8/23/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ONEWebImageCompat.h"
#import "ONEWebImageManager.h"

@interface UIButton (ONEWebCache)

- (NSURL *)one_currentImageURL;

- (NSURL *)one_imageURLForState:(UIControlState)state;

- (void)one_setImageWithURL:(NSURL *)url forState:(UIControlState)state;

- (void)one_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder;

- (void)one_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(ONEWebImageOptions)options;

- (void)one_setImageWithURL:(NSURL *)url forState:(UIControlState)state completed:(ONEWebImageDownloaderCompletedBlock)completedBlock;

- (void)one_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder completed:(ONEWebImageDownloaderCompletedBlock)completedBlock;

- (void)one_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(ONEWebImageOptions)options completed:(ONEWebImageDownloaderCompletedBlock)completedBlock;

- (void)one_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state;

- (void)one_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder;

- (void)one_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(ONEWebImageOptions)options;

- (void)one_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder completed:(ONEWebImageDownloaderCompletedBlock)completedBlock;

- (void)one_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(ONEWebImageOptions)options completed:(ONEWebImageDownloaderCompletedBlock)completedBlock;

- (void)one_cancelImageLoadForState:(UIControlState)state;

- (void)one_cancelBackgourndImageLoadForState:(UIControlState)state;

@end
