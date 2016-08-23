//
//  ONEWebImagePrefetcher.h
//  SDWebImage Demo
//
//  Created by Simon on 8/23/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ONEWebImageManager.h"

@class ONEWebImagePrefetcher;

@protocol ONEWebImagePrefetcherDelegate <NSObject>

@optional

- (void)imagePrefetcher:(ONEWebImagePrefetcher *)imagePrefetcher didPrefetchURL:(NSURL *)imageURL finishedCount:(NSUInteger)finishedCount totalCount:(NSUInteger)totalCount;

- (void)imagePrefetcher:(ONEWebImagePrefetcher *)imagePrefetcher didPrefetchURL:(NSURL *)imageURL finishedCount:(NSUInteger)finishedCount totalCount:(NSUInteger)totalCount skippedCount:(NSUInteger)skippedCount;

@end

typedef void(^ONEWebImagePrefetcherProgressBlock)(NSUInteger noOffFinishedUrls, NSUInteger noOfTotalUrls);

typedef void(^ONEWebImagePrefetcherCompletionBlock)(NSUInteger noOfFinishedUrls, NSUInteger noIfSkippedUrls);

@interface ONEWebImagePrefetcher : NSObject

@property (strong, nonatomic, readonly)ONEWebImageManager *manager;

@property (assign, nonatomic) NSUInteger maxConcurrentDownloads;

@property (assign, nonatomic) ONEWebImageOptions options;

@property (assign, nonatomic) dispatch_queue_t prefetcherQueue;

@property (weak, nonatomic) id <ONEWebImagePrefetcherDelegate> delegate;

+ (ONEWebImagePrefetcher *)sharedImagePrefetcher;

- (instancetype)initWithImageManager:(ONEWebImageManager *)manager;

- (void)prefetchURLs:(NSArray *)urls;

- (void)prefetchURLs:(NSArray *)urls progress:(ONEWebImageDownloaderProgressBlock)progressBlock completed:(ONEWebImageDownloaderCompletedBlock)completedBlock;

- (void)cnacelPrefetching;

@end
