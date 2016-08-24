//
//  ONEWebImageDownloaderOperation.m
//  SDWebImage Demo
//
//  Created by Simon on 8/23/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import "ONEWebImageDownloaderOperation.h"
#import "UIImage+ForceDecode.h"
#import "UIImage+ONEMultiFormat.h"
#import <ImageIO/ImageIO.h>
#import "ONEWebImageManager.h"

NSString *const ONEWebImageDownloadStartNotification = @"ONEWebImageDownloadStartNotification";
NSString *const ONEWebImageDownloadReceiveResponseNotification = @"ONEWebImageDownloadReceiveResponseNotification";
NSString *const ONEWebImageDownloadStopNotification = @"ONEWebImageDownloadStopNotification";
NSString *const ONEWebImageDownloadFinishNotification = @"ONEWebImageDownloadFinishNotification";

@interface ONEWebImageDownloaderOperation ()

@property (copy, nonatomic) ONEWebImageDownloaderProgressBlock progressBlock;

@property (copy, nonatomic)ONEWebImageDownloaderCompletedBlock completedBlock;

@property (copy, nonatomic) ONEWebImageNoParamsBlock cancelBlock;

@property (assign, nonatomic, getter=isExecuting) BOOL executing;

@property (assign, nonatomic, getter=isFinished) BOOL finished;

@property (strong, nonatomic) NSMutableData *imageData;

@property (strong, nonatomic) NSURLSession *ownedSession;
@property (weak, nonatomic) NSURLSession *unownedSession;

@property (strong, nonatomic, readwrite) NSURLSessionTask *dataTask;

@property (strong, atomic) NSThread *thread;

#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;
#endif

@end

@implementation ONEWebImageDownloaderOperation {
	size_t width, height;
	UIImageOrientation orientation;
	BOOL responseFromCached;
	
}

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithRequest:(NSURLRequest *)request inSession:(NSURLSession *)session options:(ONEWebImageDownloaderOptions)options progress:(ONEWebImageDownloaderProgressBlock)progressBlock completed:(ONEWebImageDownloaderCompletedBlock)completedBlock cancel:(ONEWebImageNoParamsBlock)cancelBlock {
	if (self = [super init]) {
		_request = request;
		_shouldDecompressImages = YES;
		_options = options;
		_progressBlock = [progressBlock copy];
		_completedBlock = [completedBlock copy];
		_cancelBlock = [cancelBlock copy];
		_executing = NO;
		_finished = NO;
		_expectedSize = 0;
		_unownedSession = session;
		responseFromCached = YES;
		
	}
	
	return self;
}

- (void)start {
	@synchronized (self) {
		if (self.isCancelled) {
			self.finished = YES;
			[self reset];
			return;
		}
		
#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
		
		Class UIApplicationClass = NSClassFromString(@"UIApplication");
		BOOL hasApplication = UIApplicationClass && [UIApplicationClass respondsToSelector:@selector(sharedApplication)];
		if (hasApplication && [self shouldContinueWhenAppEntersBackground]) {
			__weak __typeof(self) weakself = self;
			UIApplication *app = [UIApplicationClass performSelector:@selector(sharedApplication)];
			self.backgroundTaskId = [app beginBackgroundTaskWithExpirationHandler:^{
				__strong __typeof(weakself) strongSelf = weakself;
				
				if (strongSelf) {
					[strongSelf cancel];
					
					[app endBackgroundTask:strongSelf.backgroundTaskId];
				}
			}];
		}
#endif
		NSURLSession *session = self.unownedSession;
		if (!self.unownedSession) {
			NSURLSessionConfiguration *sessionConfigure = [NSURLSessionConfiguration defaultSessionConfiguration];
			sessionConfigure.timeoutIntervalForRequest = 15.0;
			self.ownedSession = [NSURLSession sessionWithConfiguration:sessionConfigure delegate:self delegateQueue:nil];
			session = self.ownedSession;
			
		}
		
		self.dataTask = [session dataTaskWithRequest:self.request];
		self.executing = YES;
		self.thread = [NSThread currentThread];
	}
	
	[self.dataTask resume];
	
	if (self.dataTask) {
		if (self.progressBlock) {
			self.progressBlock(0, NSURLResponseUnknownLength);
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:ONEWebImageDownloadStartNotification object:self];
			
		});
	}
	else {
		if (self.completedBlock) {
			self.completedBlock(nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"Connection can't be initialized"}], YES);
			
		}
	}

#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
	Class UIApplicationClass = NSClassFromString(@"UIApplication");
	if(!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
		return;
	}
	if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
		UIApplication * app = [UIApplication performSelector:@selector(sharedApplication)];
		[app endBackgroundTask:self.backgroundTaskId];
		self.backgroundTaskId = UIBackgroundTaskInvalid;
	}
#endif
	
}

- (void)cancel {
	@synchronized (self) {
		if (self.thread) {
			[self performSelector:@selector(cancelInteralAnddStop) onThread:self.thread withObject:nil waitUntilDone:NO];
		} else {
			[self cancelInteral];
		}
	}
}

- (void)cancelInteralAndStop {
	if (self.isFinished) {
		return;
	}
	
	[self cancelInteral];
}

- (void)cancelInteral {
	if (self.isFinished) {
		return;
	}
	
	[super cancel];
	
	if (self.cancelBlock) {
		self.cancelBlock();
	}
	
	if (self.dataTask) {
		[self.dataTask cancel];
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:ONEWebImageDownloadStopNotification object:self];
		});
		
		if (self.isExecuting) {
			self.executing = NO;
		}
		
		if (!self.isFinished) {
			self.finished = YES;
		}
	}
	
	[self reset];
	
}

- (void)done {
	self.finished = YES;
	self.executing = NO;
	[self reset];
}

- (void)reset {
	self.cancelBlock = nil;
	self.completedBlock = nil;
	self.progressBlock = nil;
	self.dataTask = nil;
	self.imageData = nil;
	self.thread = nil;
	
	if (self.ownedSession) {
		[self.ownedSession invalidateAndCancel];
		self.ownedSession = nil;
	}
}

- (void)setFinished:(BOOL)finished {
	[self willChangeValueForKey:@"isFinished"];
	_finished = finished;
	[self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
	[self willChangeValueForKey:@"isExecuting"];
	_executing = executing;
	[self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isConcurrent {
	return YES;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
	if (![response respondsToSelector:@selector(statusCode)] || ([(NSHTTPURLResponse *)response statusCode] < 400 && [(NSHTTPURLResponse*)response statusCode] != 304)) {
		NSInteger expected = response.expectedContentLength > 0 ? (NSInteger)response.expectedContentLength : 0;
		self.expectedSize = expected;
		if (self.progressBlock) {
			self.progressBlock(0, expected);
		}
		
		self.imageData = [[NSMutableData alloc] initWithCapacity:expected];
		self.response = response;
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:ONEWebImageDownloadReceiveResponseNotification object:self];
			
		});
		
	}
	else {
		NSUInteger code = [(NSHTTPURLResponse *)response statusCode];
		if (code == 304) {
			[self cancelInteral];
		} else {
			[self.dataTask cancel];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:ONEWebImageDownloadStopNotification object:self];
			
		});
		
		if (self.completedBlock) {
			self.completedBlock(nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:[(NSHTTPURLResponse *)response statusCode] userInfo:nil], YES);
		}
		
		[self done];
	}
	
	if (completionHandler) {
		completionHandler(NSURLSessionResponseAllow);
	}
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
	[self.imageData appendData:data];
	if (self.options & ONEWebImageDownloaderProgressiveDownload && self.expectedSize > 0 && self.completedBlock) {
		
		const NSInteger totalSize = self.imageData.length;
		CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)self.imageData, NULL);
		if (width + height == 0) {
			CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
			if (properties) {
				
				NSInteger orientatioValue = -1;
				CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
				if (val) {
					CFNumberGetValue(val, kCFNumberLongType, &height);
				}
				
				val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
				if (val) {
					CFNumberGetValue(val, kCFNumberLongType, &width);
				}
				
				val = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
				if (val) {
					CFNumberGetValue(val, kCFNumberNSIntegerType, &orientatioValue);
				}
				
				CFRelease(properties);
				
				orientation = [[self class] orientationFromPropertyValue:(orientatioValue == -1 ? 1 : orientatioValue)];
			}
		}
		
		if (width + height > 0 && totalSize < self.expectedSize) {
			CGImageRef partialImageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
			
#ifdef TARGET_OS_IPHONE
			if (partialImageRef) {
				const size_t partialHeight = CGImageGetHeight(partialImageRef);
				CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
				CGContextRef bmContext =CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
				
				if (bmContext) {
					CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = partialHeight}, partialImageRef);
					CGImageRelease(partialImageRef);
					partialImageRef = CGBitmapContextCreateImage(bmContext);
					CGContextRelease(bmContext);
					
				}
				else {
					CGImageRelease(partialImageRef);
					partialImageRef = nil;
				}
			}
			
#endif
			
			if (partialImageRef) {
				UIImage *image = [UIImage imageWithCGImage:partialImageRef scale:1 orientation:orientation];
				NSString *key = [[ONEWebImageManager sharedManager] cacheKeyForURL:self.request.URL];
				UIImage *scaledImage = [self scaledImageForKey:key image:image];
				if (self.shouldDecompressImages) {
					image = [UIImage decodeImageWithImage:scaledImage];
				}
				else {
					image = scaledImage;
					
				}
				CGImageRelease(partialImageRef);
				dispatch_main_sync_safe(^{
					if (self.completedBlock) {
						self.completedBlock(image, nil, nil, NO);
					}
				});
				
			}
		}
		
		CFRelease(imageSource);
	}
	
	if (self.progressBlock) {
		self.progressBlock(self.imageData.length, self.expectedSize);
		
	}
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler {
	
	responseFromCached = NO;
	NSCachedURLResponse *cachedResponse = proposedResponse;
	if (self.request.cachePolicy == NSURLRequestReloadIgnoringLocalCacheData) {
		cachedResponse = nil;
	}
	
	if (completionHandler) {
		completionHandler(cachedResponse);
	}
}

#pragma mark - NSURLSessionTaskDelegate;
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
	@synchronized (self) {
		self.thread = nil;
		self.dataTask = nil;
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:ONEWebImageDownloadStopNotification object:self];
			if (!error) {
				[[NSNotificationCenter defaultCenter] postNotificationName:ONEWebImageDownloadFinishNotification object:self];
			}
		});
	}
	
	if (error) {
		if (self.completedBlock) {
			self.completedBlock(nil, nil, error, YES);
		}
	}
	else {
		ONEWebImageDownloaderCompletedBlock completedBlock = self.completedBlock;
		if (![[NSURLCache sharedURLCache] cachedResponseForRequest:_request]) {
			responseFromCached = NO;
		}
		
		if (completedBlock) {
			if (self.options & ONEWebImageDownloaderIgnoreCachedResponse && responseFromCached) {
				completedBlock(nil, nil, nil, YES);
			}
			else if (self.imageData) {
				UIImage *image = [UIImage one_imageWithData:self.imageData];
				NSString *key = [[ONEWebImageManager sharedManager] cacheKeyForURL:self.request.URL];
				image = [self scaledImageForKey:key image:image];
				
				if (!image.images) {
					if (self.shouldDecompressImages) {
						image = [UIImage decodeImageWithImage:image];
					}
				}
				
				if (CGSizeEqualToSize(image.size, CGSizeZero)) {
					completedBlock(nil, nil, [NSError errorWithDomain:ONEWebImageErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"Downloaded  image has 0 pixels"}], YES);
				
				}
				else {
					completedBlock(image, self.imageData, nil, YES);
				}
			}
			else {

				completedBlock(nil, nil, [NSError errorWithDomain:ONEWebImageErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:@"Image Data is nil"}], YES);
			}
		}
	}
	
	self.completionBlock = nil;
	[self done];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
	NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengeRejectProtectionSpace;
	__block NSURLCredential *credential = nil;
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		
		if (!(self.options & ONEWebImageAllowInvalidSSLCertificates)) {
			disposition = NSURLSessionAuthChallengePerformDefaultHandling;
		}
		else {
	
			credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
	
			disposition = NSURLSessionAuthChallengeUseCredential;
		}
	}
	else {
		if ([challenge previousFailureCount] == 0) {
			if (self.credential) {
				credential = self.credential;
				disposition = NSURLSessionAuthChallengeUseCredential;
				
			}
			else {
				disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
			}
		}
		else {
			disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
		}
	}
	
	if (completionHandler) {
		completionHandler(disposition, credential);
	}
}

#pragma mark Helper methods

+ (UIImageOrientation)orientationFromPropertyValue:(NSInteger)value {
	switch (value) {
		case 1:
			return UIImageOrientationUp;
		case 3:
			return UIImageOrientationDown;
		case 8:
			return UIImageOrientationLeft;
		case 6:
			return UIImageOrientationRight;
		case 2:
			return UIImageOrientationUpMirrored;
		case 4:
			return UIImageOrientationDownMirrored;
		case 5:
			return UIImageOrientationLeftMirrored;
		case 7:
			return UIImageOrientationRightMirrored;
		default:
			return UIImageOrientationUp;
	}
}

- (UIImage *)scaledImageForKey:(NSString *)key image:(UIImage *)image {
	return ONEScaleImageKey(key, image);
}

- (BOOL)shouldContinueWhenAppEntersBackground {
	return self.options & ONEWebImageDownloaderContinueInBackground;
}

@end
