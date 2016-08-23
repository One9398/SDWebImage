//
//  UIImageView+ONEWebCache.h
//  ONEWebImage
//
//  Created by Simon on 7/10/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ONEWebImageCompat.h"
#import "ONEWebImageManager.h"

@interface UIImageView (ONEWebCache)

- (NSURL *)one_imageURL;

- (void)one_setImageWithURL:(NSURL *)url;

- (void)one_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder;

- (void)one_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(ONEWebImageOptions)options;

- (void)one_setImageWithURL:(NSURL *)url completed:(ONEWebImageCompletionBlock)completedBlock;

- (void)one_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(ONEWebImageCompletionBlock)completedBlcok;

- (void)one_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(ONEWebImageOptions)options completed:(ONEWebImageCompletionBlock)completedBlock;

- (void)one_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(ONEWebImageOptions)options progress:(ONEWebImageDownloaderProgressBlock)progressBlock completed:(ONEWebImageCompletionBlock)completedBlock;

- (void)one_setImageWithPreviousCachedImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(ONEWebImageOptions)options progress:(ONEWebImageDownloaderProgressBlock)progressBlock completed:(ONEWebImageCompletionBlock)completedBlock;

- (void)one_setAnimationImagesWithURLs:(NSArray *)arrayOfURLs;

- (void)one_cancelCurrentImageLoad;

- (void)one_cancelCurrentAnimationImagesLoad;

- (void)one_setShowActivityIndicatorView:(BOOL)show;

- (void)one_setIndicatorStyle:(UIActivityIndicatorViewStyle)style;

@end
