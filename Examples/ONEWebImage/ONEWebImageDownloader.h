//
//  ONEWebImageDownloader.h
//  SDWebImage Demo
//
//  Created by Simon on 8/23/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ONEWebImageCompat.h"
#import "ONEWebImageOperation.h"

typedef NS_OPTIONS(NSUInteger, ONEWebImageDownloaderOptions) {
	
	ONEWebImageDownloaderLowPriority = 1 << 0,
	
	ONEWebImageDownloaderProgressiveDownload = 1 << 1,
	
	ONEWebImageDownloaderUserNSURLCache = 1 << 2,
	
	ONEWebImageDownloaderIgnoreCachedResponse = 1 << 3,
	
	ONEWebImageDownloaderContinueInBackground = 1 << 4,
	
	ONEWebImageDownloaderHandleCookies = 1<< 5,
	
	ONEWebImageDownloaderAllowInvalidSSLCertificates = 1 << 6,
	
	ONEWebImageDownloaderHighPriority = 1 << 7,
	
};

typedef NS_ENUM(NSUInteger, ONEWebImageDownloaderExecutionOrder) {

	ONEWebImageDownloaderFIFOExecutionOrder,
	
	ONEWebImageDownloaderLIFOExecutionOrder,
	
};

extern NSString *const ONEWebImageDownloadStartNotification;

extern NSString *const ONEWebImageDownloadStopNotification;

typedef void(^ONEWebImageDownloaderProgressBlock)(NSInteger receivedSize, NSInteger expectedSize);

typedef void(^ONEWebImageDownloaderCompletedBlock)(UIImage *image, NSData *data, NSError *error, BOOL finished);

typedef NSDictionary *(^ONEWebImageDownloaderHeadersFilterBlock)(NSURL *url, NSDictionary *headers);

@interface ONEWebImageDownloader : NSObject

@property (assign, nonatomic) BOOL shouldDecompressImages;

@property (assign, nonatomic) NSInteger maxConcurrentDownloads;

@property (readonly, nonatomic) NSUInteger currentDownloadCount;

@property (assign, nonatomic) NSTimeInterval downloadTimeout;

@property (assign, nonatomic) ONEWebImageDownloaderExecutionOrder executionOrder;

+ (ONEWebImageDownloader *)sharedDownloader;

@property (strong, nonatomic) NSURLCredential *urlCredential;

@property (strong, nonatomic) NSString *username;

@property (strong, nonatomic) NSString *password;

@property (nonatomic, copy) ONEWebImageDownloaderHeadersFilterBlock headersFilter;

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

- (NSString *)valueForHTTPHeaderField:(NSString *)field;

- (void)setOperationClass:(Class)operationClass;

- (id <ONEWebImageOperation>)downloadImageWithURL:(NSURL *)url options:(ONEWebImageDownloaderOptions)options progress:(ONEWebImageDownloaderProgressBlock)progressBlock completed:(ONEWebImageDownloaderCompletedBlock)completedBlcok;

- (void)setSuspended:(BOOL)suspended;

- (void)cancelALlDownloads;

@end
