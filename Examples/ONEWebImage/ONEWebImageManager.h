//
//  ONEWebImageManager.h
//  SDWebImage
//
//  Created by Simon on 7/10/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ONEWebImageCompat.h"
#import "ONEWebImageDownloader.h"
#import "ONEWebImageOperation.h"
#import "OneImageCache.h"

typedef NS_OPTIONS(NSUInteger, ONEWebImageOptions) {
    ONEWebImageRetryFailed = 1 << 0,
    ONEWebImageLowPriority = 1 << 1,
    ONEWebImageMemoryOnly = 1 << 2,
    ONEWebImageProgressiveDownload = 1 << 3,
    ONEWebImageRefreshCached = 1 << 4,
    ONEWebImageContinueInBackground = 1 << 5,
    ONEWebImageHandleCookies = 1 << 6,
    ONEWebImageAllowInvalidSSLCertificates = 1 << 7,
    ONEWebImageHighPriority = 1 << 8,
    ONEWebImageDelayPlaceholder = 1 << 9,
    ONEWebImageTransformAniamtedImage = 1 << 10,
    ONEWebImageAvoidSetImage = 1 << 11
};

typedef void(^ONEWebImageCompletionBlock)(UIImage *image, NSError *error, ONEImageCacheType cacheType, NSURL *imageURL);
typedef void(^ONEWebImageCompletionWithFinishedBlock)(UIImage *image, NSError *error, ONEImageCacheType cacheType, BOOL finished, NSURL *imageURL);
typedef NSString *(^ONEWebImageCacheKeyFilterBlock)(NSURL *url);

@class ONEWebImageManager;
@protocol ONEWebImageManagerDelegate <NSObject>

@optional
- (BOOL)imageManager:(ONEWebImageManager *)imageManager shouldDownloadImageForURL:(NSURL *)imageURL;
- (UIImage *)imageManger:(ONEWebImageManager *)imageManager transformDownloadedImage:(UIImage *)image withURL:(NSURL *)imageURL;

@end
@interface ONEWebImageManager : NSObject

@property (readwrite, nonatomic, assign) id <ONEWebImageManagerDelegate> delegate;
@property (readonly, nonatomic, strong) ONEImageCache *cache;
@property (readonly, nonatomic, strong) ONEWebImageDownloader *imageDownloader;
@property (readwrite, nonatomic, copy) ONEWebImageCacheKeyFilterBlock cacheFilterBlock;

+ (ONEWebImageManager *)sharedManager;

- (instancetype)initWithCache:(ONEImageCache *)cache downloader:(ONEWebImageDownloader *)imageDownloader;

- (id <ONEWebImageOperation>)downloadImageWithURL:(NSURL *)url options:(ONEWebImageOptions)options progress:(ONEWebImageDownloaderProgressBlock)progressBlock completed:(ONEWebImageCompletionWithFinishedBlock)completedBlock;

- (void)saveImageToCache:(UIImage *)image forURL:(NSURL *)url;

- (void)cancelAll;

- (BOOL)isRunning;

- (BOOL)cachedImageExistsForURL:(NSURL *)url;

- (BOOL)diskImageExistsForURL:(NSURL *)url;

- (void)cachedImageExistsForURL:(NSURL *)url completion:(ONEWebImageCheckCacheCompletionBlock)completionBlock;

- (void)diskImageExistsForURL:(NSURL *)url completion:(ONEWebImageCheckCacheCompletionBlock)completionBlock;

- (NSString *)cacheKeyForURL:(NSURL *)url;

@end
