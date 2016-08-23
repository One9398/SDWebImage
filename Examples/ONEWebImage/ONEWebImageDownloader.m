//
//  ONEWebImageDownloader.m
//  SDWebImage Demo
//
//  Created by Simon on 8/23/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import "ONEWebImageDownloader.h"
#import "ONEWebImageDownloaderOperation.h"
#import <ImageIO/ImageIO.h>

static NSString *const kProgressCallbackKey = @"progress";
static NSString *const kCompletedCallbackKey = @"completed";

@interface ONEWebImageDownloader () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (strong, nonatomic) NSOperationQueue *downloadQueue;

@property (weak, nonatomic) NSOperation *lastAddedOperation;

@property (assign, nonatomic) Class	operationClass;

@property (strong, nonatomic) NSMutableDictionary *URLCallbacks;

@property (strong, nonatomic) NSMutableDictionary *HTTPHeaders;

@property (SDDispatchQueueSetterSementics, nonatomic)dispatch_queue_t barrierQueue;

@property (strong, nonatomic) NSURLSession *session;

@end

@implementation ONEWebImageDownloader

+ (void)initialize {
	
}

- (instancetype)init {
	if (self = [super init]) {
		_operationClass = [ONEWebImageDownloaderOperation class];
		_shouldDecompressImages = YES;
		_executionOrder = ONEWebImageDownloaderFIFOExecutionOrder;
		_downloadQueue = [NSOperationQueue new];
		_downloadQueue.maxConcurrentOperationCount = 6;
		_URLCallbacks = [NSMutableDictionary dictionary];
		
#ifdef ONE_WEBP
		_HTTPHeaders = [@{@"Accept": @"image/webp,image/*;q=0.8"} mutableCopy];
# else
		_HTTPHeaders = [@{@"Accept": @"image/*;q=0.8"} mutableCopy];
#endif
		_barrierQueue = dispatch_queue_create("com.one.ONEWebImageDownloaderBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
		_downloadTimeout = 15.0;
		
		NSURLSessionConfiguration *sessionConfigure = [NSURLSessionConfiguration defaultSessionConfiguration];
		sessionConfigure.timeoutIntervalForRequest = _downloadTimeout;
		
		self.session = [NSURLSession sessionWithConfiguration:sessionConfigure delegate:self delegateQueue:nil];
		
	}
	
	return self;
}

- (void)dealloc {
	[self.session invalidateAndCancel];
	self.session = nil;
	
	[self.downloadQueue cancelAllOperations];
	SDDispatchQueueRelease(_barrierQueue);
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
	if (value) {
		self.HTTPHeaders[field] = value;
	} else {
		[self.HTTPHeaders removeObjectForKey:field];
	}
}

- (NSString *)valueForHTTPHeaderField:(NSString *)field {
	return self.HTTPHeaders[field];
	
}

- (void)setMaxConcurrentDownloads:(NSInteger)maxConcurrentDownloads {
	_downloadQueue.maxConcurrentOperationCount = maxConcurrentDownloads;
	
}

- (NSUInteger)currentDownloadCount {
	return _downloadQueue.operationCount;
}

- (NSInteger)maxConcurrentDownloads {
	return _downloadQueue.maxConcurrentOperationCount;
	
}

-(void)setOperationClass:(Class)operationClass {
	_operationClass = operationClass ?: [ONEWebImageDownloaderOperation class];
	
}

- (id<ONEWebImageOperation>)downloadImageWithURL:(NSURL *)url options:(ONEWebImageDownloaderOptions)options progress:(ONEWebImageDownloaderProgressBlock)progressBlock completed:(ONEWebImageDownloaderCompletedBlock)completedBlcok {
	__block ONEWebImageDownloaderOperation *operation;
	__weak __typeof(self)weakSelf = self;
	[self addProgressCallback:progressBlock completedBlock:completedBlcok forURL:url createCallback:^{
		NSTimeInterval timeoutInterval = weakSelf.downloadTimeout;
		if (timeoutInterval == 0.0) {
			timeoutInterval = 15.0;
		}
		
		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:(options & ONEWebImageDownloaderUserNSURLCache ? NSURLRequestUseProtocolCachePolicy : NSURLRequestReloadIgnoringLocalCacheData) timeoutInterval:timeoutInterval];
		request.HTTPShouldHandleCookies = (options & ONEWebImageDownloaderHandleCookies);
		request.HTTPShouldUsePipelining = YES;
		if (weakSelf.HTTPHeaders) {
			request.allHTTPHeaderFields = weakSelf.headersFilter(url, [weakSelf.HTTPHeaders copy]);
		} else {
			request.allHTTPHeaderFields = weakSelf.HTTPHeaders;
		}
		
		operation = [[weakSelf.operationClass alloc] initWithRequest:request inSession:self.session options:options progress:^(NSInteger receivedSize, NSInteger expectedSize) {
			ONEWebImageDownloader *strongSelf = weakSelf;
			if (!strongSelf) {
				return ;
			}
			
			__block NSArray *callbackForURL;
			
			dispatch_sync(strongSelf.barrierQueue, ^{
				callbackForURL = [strongSelf.URLCallbacks[url] copy];
			});
			
			for (NSDictionary *callBacks in callbackForURL) {
				dispatch_async(dispatch_get_main_queue(), ^{
					
					
					ONEWebImageDownloaderProgressBlock progressCallback = callBacks[kProgressCallbackKey];
					
					if (progressCallback) {
						progressCallback(receivedSize, expectedSize);
					}
				});
			}
			
		} completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
			ONEWebImageDownloader *strongSelf = weakSelf;
			if (!strongSelf) {
				return ;
			}
			
			__block NSArray *callbacksForURL;
			dispatch_barrier_sync(strongSelf.barrierQueue, ^{
				callbacksForURL = [self.URLCallbacks[url] copy];
				if (finished) {
					[strongSelf.URLCallbacks removeObjectForKey:url ];
					
					for (NSDictionary *callBacks in callbacksForURL) {
						ONEWebImageDownloaderCompletedBlock completedBlock = callBacks[kCompletedCallbackKey];
						if (completedBlock) {
							completedBlock(image, data, error, finished);
						}
					}
				}
			});
			
		} cancel:^{
			ONEWebImageDownloader *strongSelf = weakSelf;
			if (!strongSelf) {
				return ;
			}
			
			dispatch_barrier_sync(strongSelf.barrierQueue, ^{
				[strongSelf.URLCallbacks removeObjectForKey:url];
			});
		}];
		
		operation.shouldDecompressImages = weakSelf.shouldDecompressImages;
		if (weakSelf.urlCredential) {
			operation.credential = weakSelf.urlCredential;
		} else if (weakSelf.username && weakSelf.password) {
			operation.credential = [NSURLCredential credentialWithUser:weakSelf.username password:weakSelf.password persistence:NSURLCredentialPersistenceForSession];
		}
		
		if (options & ONEWebImageDownloaderHighPriority) {
			operation.queuePriority = NSOperationQueuePriorityHigh;
			
		} else if (options & ONEWebImageDownloaderLowPriority) {
			operation.queuePriority = NSOperationQueuePriorityLow;
		}
		
		[weakSelf.downloadQueue addOperation:operation];
		if (weakSelf.executionOrder == ONEWebImageDownloaderLIFOExecutionOrder) {
			[weakSelf.lastAddedOperation addDependency:operation];
			weakSelf.lastAddedOperation = operation;
		}
	}];
	
	return operation;
	
}

- (void)addProgressCallback:(ONEWebImageDownloaderProgressBlock)progressBlock completedBlock:(ONEWebImageDownloaderCompletedBlock)completedBlock forURL:(NSURL *)url createCallback:(ONEWebImageNoParamsBlock)createCallback {
	
	if (url == nil) {
		if (completedBlock != nil) {
			completedBlock(nil, nil, nil, NO);
		}
		
		return;
		
	}
	
	dispatch_barrier_sync(self.barrierQueue, ^{
		BOOL first = NO;
		if (!self.URLCallbacks[url]) {
			self.URLCallbacks[url] = [NSMutableArray new];
			first = YES;
			
		}
		
		NSMutableArray *callbacksForURL = self.URLCallbacks[url];
		NSMutableDictionary *callbacks = [NSMutableDictionary new];
		if (progressBlock) {
			callbacks[kProgressCallbackKey] = [progressBlock copy];
		}
		
		if (completedBlock) {
			callbacks[kCompletedCallbackKey] = [completedBlock copy];
		}
		
		[callbacksForURL addObject:callbacks];
		self.URLCallbacks[url] = callbacksForURL;
		
		if (first) {
			createCallback();
		}
	});
}

- (void)setSuspended:(BOOL)suspended {
	[self.downloadQueue setSuspended:suspended];
	
}

- (void)cancelALlDownloads {
	[self.downloadQueue cancelAllOperations];
}

#pragma mark - Helper Methods
- (ONEWebImageDownloaderOperation *)operationWithTask:(NSURLSessionTask *)task {
	ONEWebImageDownloaderOperation *returnOperation = nil;
	
	for (ONEWebImageDownloaderOperation *operation in self.downloadQueue.operations) {
		if (operation.dataTask.taskIdentifier == task.taskIdentifier) {
			returnOperation = operation;
			break;
		}
	}
	
	return returnOperation;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler {
	ONEWebImageDownloaderOperation *dataOperation = [self operationWithTask:dataTask];
	
	[dataOperation URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
	
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(nonnull NSCachedURLResponse *)proposedResponse completionHandler:(nonnull void (^)(NSCachedURLResponse * _Nullable))completionHandler {
	ONEWebImageDownloaderOperation *dataOperation = [self operationWithTask:dataTask];
	
	[dataOperation URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
	
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
	ONEWebImageDownloaderOperation *dataOperation = [self operationWithTask:task];
	
	[dataOperation URLSession:session task:task didCompleteWithError:error];
	
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
	
	ONEWebImageDownloaderOperation *dataOperation = [self operationWithTask:task];
	
	[dataOperation URLSession:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
	
}
@end
