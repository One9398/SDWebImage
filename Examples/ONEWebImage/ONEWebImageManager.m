//
//  ONEWebImageManager.m
//  ONEWebImage
//
//  Created by Simon on 7/10/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import "ONEWebImageManager.h"
#import <objc/message.h>

@interface ONEWebImageCombinedOperation : NSObject <ONEWebImageOperation>
@property (assign, nonatomic, getter=isCanceled) BOOL cancelled;
@property (copy, nonatomic) ONEWebImageNoParamsBlock cancelBlock;
@property (copy, nonatomic) NSOperation *cacheOperation;

@end

@interface ONEWebImageManager ()

@property (readwrite, nonatomic, strong) ONEImageCache *imageCache;
@property (readwrite, nonatomic, strong) ONEWebImageDownloader *imageDownloader;
@property (readwrite, nonatomic, strong) NSMutableSet *failedURLs;
@property (readwrite, nonatomic, strong) NSMutableArray *runningOperations;



@end

@implementation ONEWebImageManager

+ (ONEWebImageManager *)sharedManager {
    static dispatch_once_t onceToken;
    static id instance;
    
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init {
    ONEImageCache *imageCache = [ONEImageCache sharedImageCache];
    ONEWebImageDownloader *imageDownloader = [ONEWebImageDownloader sharedDownloader];
    return [self initWithCache:imageCache downloader:imageDownloader];
    
}

- (instancetype)initWithCache:(ONEImageCache *)cache downloader:(ONEWebImageDownloader *)imageDownloader {
    if (self = [super init]) {
        _imageCache = cache;
        _imageDownloader = imageDownloader;
        _runningOperations = [NSMutableArray new];
    }
    
    return self;
}

- (NSString *)cacheKeyForURL:(NSURL *)url {
    if (!url) {
        return @"";
        
    }
    
    if (self.cacheFilterBlock) {
        return self.cacheFilterBlock(url);
    } else {
        return [url absoluteString];
    }
}

- (BOOL)cachedImageExistsForURL:(NSURL *)url {
    NSString *key = [self cacheKeyForURL:url];
    if ([self.imageCache imageFromMemoryCacheForKey:key] != nil) {
        return YES;
    }
    
    return [self.imageCache diskImageExistsWithKey:key];
}

- (BOOL)diskImageExistsForURL:(NSURL *)url {
    NSString *key = [self cacheKeyForURL:url];
    return [self.imageCache diskImageExistsWithKey:key];
    
}

- (void)cachedImageExistsForURL:(NSURL *)url completion:(ONEWebImageCheckCacheCompletionBlock)completionBlock {
    NSString *key = [self cacheKeyForURL:url];
    BOOL isInMemoryCache = ([self.imageCache imageFromMemoryCacheForKey:key] != nil);
    if (isInMemoryCache) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(YES);
            }
        });
        return;
    }
    
    [self.imageCache diskImageExistsWithKey:key completion:^(BOOL isInCache) {
        
        if (completionBlock) {
            completionBlock(isInCache);
        }
    }];
    
}

- (id <ONEWebImageOperation>)downloadImageWithURL:(NSURL *)url options:(ONEWebImageOptions)options progress:(ONEWebImageDownloaderProgressBlock)progressBlock completed:(ONEWebImageCompletionWithFinishedBlock)completedBlock {
    NSAssert(completedBlock != nil, @"if you mean to prefetch image, use-[ONEWebImagePrefetcher prefetchURLS] instead");
    
    if ([url isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:(NSString *)url];
        
    }
    
    if (![url isKindOfClass:NSURL.class]) {
        url = nil;
        
    }
    
    __block ONEWebImageCombinedOperation *operation = [ONEWebImageCombinedOperation new];
    __weak ONEWebImageCombinedOperation *weakOperation = operation;
    
    BOOL isFailedURL = NO;
    @synchronized (self.failedURLs) {
        isFailedURL = [self.failedURLs containsObject:url];
    }
    
    if (url.absoluteString.length == 0 || ((!operation & ONEWebImageRetryFailed) && isFailedURL)) {
        dispatch_main_sync_safe(^{
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil];
            completedBlock(nil,error,ONEImageCacheTypeNone, YES, url);
        });
        
        return operation;
        
    }
    
    @synchronized (self.runningOperations) {
        [self.runningOperations removeObject:operation];
        
    }
    
    NSString *key = [self cacheKeyForURL:url];
    
    operation.cacheOperation = [self.imageCache queryDiskCacheForKey:key done:^(UIImage *image, ONEImageCacheType cacheType) {
        if (operation.isCanceled) {
            @synchronized (self.runningOperations) {
                [self.runningOperations removeObject:operation];
                
            }
            return ;
        }
        
        if ((!image || options & ONEWebImageRefreshCached) && (![self.delegate respondsToSelector:@selector(imageManager:shouldDownloadImageForURL:)] || [self.delegate imageManager:self shouldDownloadImageForURL:url])) {
            
            if (image && (options & ONEWebImageRefreshCached)) {
                dispatch_main_sync_safe(^{
                    completedBlock(image, nil, cacheType, YES, url);
                });
            }
            
            ONEWebImageDownloaderOptions downloaderOperations = 0;
            if (options & ONEWebImageLowPriority) {
                downloaderOperations |= ONEWebImageDownloaderLowPriority;
            }
            
            if (options & ONEWebImageProgressiveDownload) {
                downloaderOperations |= ONEWebImageDownloaderProgressiveDownload;
            }
            
            if (options & ONEWebImageRefreshCached) {
                downloaderOperations |= ONEWebImageDownloaderUserNSURLCache;                
            }
			
            if (options & ONEWebImageContinueInBackground) {
                downloaderOperations |= ONEWebImageDownloaderContinueInBackground;
            }
            
            if (options & ONEWebImageHandleCookies) {
                downloaderOperations |= ONEWebImageDownloaderHandleCookies;
            }
            
            if (options & ONEWebImageHighPriority) {
                downloaderOperations |= ONEWebImageDownloaderHighPriority;
            }
            
            if (options & ONEWebImageAllowInvalidSSLCertificates) {
                downloaderOperations |= ONEWebImageDownloaderAllowInvalidSSLCertificates;
            }
            
            if (image && (options & ONEWebImageRefreshCached)) {
                downloaderOperations &= ~ONEWebImageDownloaderProgressiveDownload;
                downloaderOperations |= ONEWebImageDownloaderIgnoreCachedResponse;
            }

        }
        else if(image) {
            
        }
        else {
            
        }
        
    }];
    
    return operation;
    
}

- (void)saveImageToCache:(UIImage *)image forURL:(NSURL *)url {
	
}

- (void)diskImageExistsForURL:(NSURL *)url completion:(ONEWebImageCheckCacheCompletionBlock)completionBlock {
	
}


@end

@implementation ONEWebImageCombinedOperation

- (void)cancel {
	
}

@end;