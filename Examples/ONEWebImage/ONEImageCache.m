//
//  OneImageCache.m
//  SDWebImage Demo
//
//  Created by Simon on 8/23/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import "ONEImageCache.h"
#import "UIImage+ForceDecode.h"
#import "UIImage+ONEMultiFormat.h"
#import <CommonCrypto/CommonDigest.h>

@interface AutoPurgeCache : NSCache
@end

@implementation AutoPurgeCache

- (id)init {
	self = [super init];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

@end

static const NSInteger kDefaultCacheMaxCacheAge = 60 * 60 * 24 * 7;
static unsigned char kPNGSignatureBytes[8] = {0x89, 0x50, 0x4e, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
static NSData *kPNGSignatureData = nil;

BOOL ImageDataHasPNGPreffix(NSData *data);

BOOL ImageDataHasPNGPreffix(NSData *data) {
	NSUInteger pngSignatureLength = [kPNGSignatureData length];
	if ([data length] >= pngSignatureLength) {
		if ([[data subdataWithRange:NSMakeRange(0, pngSignatureLength)] isEqualToData:kPNGSignatureData]) {
			return YES;
		}
	}
	
	return NO;
}

FOUNDATION_STATIC_INLINE NSUInteger ONECacheCostForImage(UIImage *image) {
	return image.size.height * image.size.width * image.scale * image.scale;
}

@interface ONEImageCache ()

@property (strong, nonatomic) NSCache *memCache;
@property (strong, nonatomic) NSString *diskCachePath;
@property (strong, nonatomic) NSMutableArray *customPaths;
@property (SDDispatchQueueSetterSementics)dispatch_queue_t ioQueue;

@end

@implementation ONEImageCache {
	NSFileManager *_fileManager;
}

+ (ONEImageCache *)sharedImageCache {
	static dispatch_once_t onceToken;
	static id instance;
	dispatch_once(&onceToken, ^{
		instance = [self new];
	});
	
	return instance;
}

- (instancetype)init {
	return [self initWithNameSpace:@"default"];
}

- (instancetype)initWithNameSpace:(NSString *)nameSpace {
	NSString *path = [self makeDiskCachePath:nameSpace];
	
	return [self initWithNameSpace:nameSpace diskCacheDirectory:path];
}

- (instancetype)initWithNameSpace:(NSString *)nameSpace diskCacheDirectory:(NSString *)directory {
	if (self = [super init]) {
		NSString *fullNameSpace = [@"com.hackemist.ONEWebImageCache." stringByAppendingString:nameSpace];
		kPNGSignatureData = [NSData dataWithBytes:kPNGSignatureBytes length:8];
		
		_ioQueue = dispatch_queue_create("com.hackmist.ONEWebImageCache", DISPATCH_QUEUE_SERIAL);
		_maxCacheAge = kDefaultCacheMaxCacheAge;
		_memCache = [[AutoPurgeCache alloc] init];
		_memCache.name = fullNameSpace;
		
		if (directory) {
			_diskCachePath = [directory stringByAppendingPathComponent:fullNameSpace];
		} else {
			NSString *path = [self makeDiskCachePath:nameSpace];
			_diskCachePath = path;
		}
		
		_shouldDisbaleiCloud = YES;
		_shouldDecompressImages = YES;
		_shouldCacheImagesInMemory = YES;
		
		dispatch_sync(_ioQueue, ^{
			_fileManager = [NSFileManager new];
		});
		
#if TARGET_OS_IOS
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearMemory) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanDisk) name:UIApplicationWillTerminateNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgroundCleanDisk) name:UIApplicationDidEnterBackgroundNotification object:nil];
#endif
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	SDDispatchQueueRelease(_ioQueue);
}

- (void)addReadOnlyCachePath:(NSString *)path {
	if (!self.customPaths) {
		self.customPaths = [NSMutableArray new];
	}
	
	if (![self.customPaths containsObject:path]) {
		[self.customPaths addObject:path];
	}
}

- (NSString *)cachePathForKey:(NSString *)key inPath:(NSString *)inPath {
	NSString *fileName = [self cachedFileNameForKey:key];
	return [inPath stringByAppendingPathComponent:fileName];
}

- (NSString *)defaultCachePathForKey:(NSString *)key {
	return [self cachePathForKey:key inPath:self.diskCachePath];
	
}

#pragma mark - Private
- (NSString *)cachedFileNameForKey:(NSString *)key {
	const char *str = [key UTF8String];
	if (str == NULL) {
		str = "";
	}
	
	unsigned char r[CC_MD5_DIGEST_LENGTH];
	CC_MD5(str, (CC_LONG)strlen(str), r);
	NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
						  r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
						  r[11], r[12], r[13], r[14], r[15], [[key pathExtension] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@".%@", [key pathExtension]]];
	
	return filename;
	
}

- (NSString *)makeDiskCachePath:(NSString *)fullNameSpace {
	NSArray *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	
	return [path[0] stringByAppendingPathComponent:fullNameSpace];
	
}

- (void)storeImage:(UIImage *)image recalculateFromImage:(BOOL)recalculate imageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk {
	if (!image || !key) {
		return;
	}
	
	if (self.shouldCacheImagesInMemory) {
		NSUInteger cost = ONECacheCostForImage(image);
		[self.memCache setObject:image forKey:key cost:cost];
	}
	
	if (toDisk) {
		dispatch_async(self.ioQueue, ^{
			NSData *data = imageData;
			
			if (image && (recalculate || !data)) {
#if TARGET_OS_IPHONE
				// We need to determine if the image is a PNG or a JPEG
				// PNGs are easier to detect because they have a unique signature (http://www.w3.org/TR/PNG-Structure.html)
				// The first eight bytes of a PNG file always contain the following (decimal) values:
				// 137 80 78 71 13 10 26 10
				
				// If the imageData is nil (i.e. if trying to save a UIImage directly or the image was transformed on download)
				// and the image has an alpha channel, we will consider it PNG to avoid losing the transparency
				int alphaInfo = CGImageGetAlphaInfo(image.CGImage);
				BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
								  alphaInfo == kCGImageAlphaNoneSkipFirst ||
								  alphaInfo == kCGImageAlphaNoneSkipLast);
				BOOL imageIsPng = hasAlpha;
				
				// But if we have an image data, we will look at the preffix
				if ([imageData length] >= [kPNGSignatureData length]) {
					imageIsPng = ImageDataHasPNGPreffix(imageData);
				}
				
				if (imageIsPng) {
					data = UIImagePNGRepresentation(image);
				}
				else {
					data = UIImageJPEGRepresentation(image, (CGFloat)1.0);
				}
#else
				data = [NSBitmapImageRep representationOfImageRepsInArray:image.representations usingType: NSJPEGFileType properties:nil];
#endif
			}
			
			[self storeImageDataToDisk:data forKey:key];
			
		});
	}
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key {
	[self storeImage:image recalculateFromImage:YES imageData:nil forKey:key toDisk:YES];
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk {
	[self storeImage:image recalculateFromImage:YES imageData:nil forKey:key toDisk:toDisk];
	
}

- (void)storeImageDataToDisk:(NSData *)imageData forKey:(NSString *)key {
	if (!imageData) {
		return;
	}
	
	if (![_fileManager fileExistsAtPath:_diskCachePath]) {
		[_fileManager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	NSString *cachePathForKey = [self defaultCachePathForKey:key];
	NSURL *fileURL = [NSURL fileURLWithPath:cachePathForKey];

	[_fileManager createFileAtPath:cachePathForKey contents:imageData attributes:nil];
	
	if (self.shouldDisbaleiCloud) {
		[fileURL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:nil];
	}
	
}

- (BOOL)diskImageExistsWithKey:(NSString *)key {
	BOOL exists = NO;
	exists = [[NSFileManager defaultManager] fileExistsAtPath:[self defaultCachePathForKey:key]];
	
	if (!exists) {
		exists = [[NSFileManager defaultManager] fileExistsAtPath:[[self defaultCachePathForKey:key] stringByDeletingPathExtension]];
		
	}
	
	return exists;
}

- (void)diskImageExistsWithKey:(NSString *)key completion:(ONEWebImageCheckCacheCompletionBlock)completionBlock {
	dispatch_async(_ioQueue, ^{
		BOOL exists = [_fileManager fileExistsAtPath:[self defaultCachePathForKey:key]];
		if (!exists) {
			exists = [_fileManager fileExistsAtPath:[[self defaultCachePathForKey:key] stringByDeletingPathExtension]];
		}
		
		if (completionBlock) {
			dispatch_async(dispatch_get_main_queue(), ^{
				completionBlock(exists);
				
			});
			
		}
	});
}

- (UIImage *)imageFromMemoryCacheForKey:(NSString *)key {
	return [self.memCache objectForKey:key];
	
}

- (UIImage *)imageFromDiskCacheForKey:(NSString *)key {
	UIImage *image = [self imageFromDiskCacheForKey:key];
	
	if (image) {
		return image;
	}
	
	UIImage *diskImage = [self diskImageForKey:key];
	
	if (diskImage && self.shouldCacheImagesInMemory) {
		NSUInteger cost = ONECacheCostForImage(diskImage);
		[self.memCache setObject:diskImage forKey:key cost:cost];
	}
	
	return diskImage;
}

- (NSData *)diskImageDataBySearchingAllPathsForKey:(NSString *)key {
	NSString *defaultPath = [self defaultCachePathForKey:key];
	NSData *data = [NSData dataWithContentsOfFile:defaultPath];
	if (data) {
		return data;
	}
	
	data = [NSData dataWithContentsOfFile:[defaultPath stringByDeletingPathExtension]];
	if (data) {
		return data;
	}
}sadasdasdasdasdasdasdasd
}

- (UIImage *)diskImageForKey:(NSString *)key {
	
}

@end
