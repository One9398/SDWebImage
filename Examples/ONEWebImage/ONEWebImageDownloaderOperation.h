//
//  ONEWebImageDownloaderOperation.h
//  SDWebImage Demo
//
//  Created by Simon on 8/23/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ONEWebImageDownloader.h"
#import "ONEWebImageOperation.h"

extern NSString *const ONEWebImageDownloadStartNotification;
extern NSString *const ONEWebImageDownloadReceiveResponseNotification;
extern NSString *const ONEWebImageDownloadStopNotification;
extern NSString *const ONEWebImageDownloadFinishNotification;

@interface ONEWebImageDownloaderOperation : NSOperation <ONEWebImageOperation, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (strong, nonatomic, readonly) NSURLRequest  *request;

@property (strong, nonatomic, readonly) NSURLSessionTask *dataTask;

@property (assign, nonatomic) BOOL shouldDecompressImages;

@property (strong, nonatomic) NSURLCredential *credential;

@property (assign, nonatomic, readonly) ONEWebImageDownloaderOptions options;

@property (assign, nonatomic) NSInteger expectedSize;

@property (strong, nonatomic) NSURLResponse *response;

- (instancetype)initWithRequest:(NSURLRequest *)request inSession:(NSURLSession *)session options:(ONEWebImageDownloaderOptions)options progress:(ONEWebImageDownloaderProgressBlock)progressBlock completed:(ONEWebImageDownloaderCompletedBlock)completedBlock cancel:(ONEWebImageNoParamsBlock)cancelBlock;

@end
