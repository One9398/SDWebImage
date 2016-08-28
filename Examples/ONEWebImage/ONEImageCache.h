//
//  OneImageCache.h
//  SDWebImage Demo
//
//  Created by Simon on 8/23/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ONEWebImageCompat.h"

typedef NS_ENUM(NSUInteger, ONEImageCacheType) {
	
	ONEImageCacheTypeNone,
	
	ONEImageCacheTypeDisk,
	
	ONEImageCacheTypeMemory,
};

typedef void(^ONEWebImageQueryCompletedBlock)(UIImage *, ONEImageCacheType cacheType);

typedef void(^ONEWebImageCheckCacheCompletionBlock)(BOOL isInCache);

typedef void(^ONEWebImageCalcuateSzieBlock)(NSUInteger flieCount, NSUInteger totalSize);

@interface ONEImageCache : NSObject

@property (assign, nonatomic) BOOL shouldDecompressImages;

@property (assign, nonatomic) BOOL shouldCacheImagesInMemory;

@property (assign, nonatomic) BOOL shouldDisbaleiCloud;

@property (assign, nonatomic) NSUInteger maxMemoryCost;

@property (assign, nonatomic) NSUInteger maxMemoryCountLimit;

@property (assign, nonatomic) NSInteger maxCacheAge;

@property (assign, nonatomic) NSUInteger maxCacheSize;

+ (ONEImageCache *)sharedImageCache;

- (instancetype)initWithNameSpace:(NSString *)nameSpace;

- (instancetype)initWithNameSpace:(NSString *)nameSpace diskCacheDirectory:(NSString *)directory;

- (NSString *)makeDiskCachePath:(NSString *)fullNameSpace;

- (void)addReadOnlyCachePath:(NSString *)path;

- (void)storeImage:(UIImage *)image forKey:(NSString *)key;

- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk;

- (void)storeImage:(UIImage *)image recalculateFromImage:(BOOL)recalculate imageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk;

- (void)storeImageDataToDisk:(NSData *)imageData forKey:(NSString *)key;

- (NSOperation *)queryDiskCacheForKey:(NSString *)key done:(ONEWebImageQueryCompletedBlock)doneBlock;

- (UIImage *)imageFromMemoryCacheForKey:(NSString *)key;

- (UIImage *)imageFromDiskCacheForKey:(NSString *)key;

- (void)removeImageForKey:(NSString *)key;

- (void)removeImageForKey:(NSString *)key withCompletion:(ONEWebImageNoParamsBlock)completion;

- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk withCompletion:(ONEWebImageNoParamsBlock)completion;

- (void)clearMemory;

- (void)cleanDiskWithCompletionBlock:(ONEWebImageNoParamsBlock)completion;

- (void)cleanDisk;

- (NSUInteger)getSize;

- (NSUInteger)getDiskCount;

- (void)calculateSizeWithCompletion:(ONEWebImageCalcuateSzieBlock)completionBlock;

- (void)diskImageExistsWithKey:(NSString *)key completion:(ONEWebImageCheckCacheCompletionBlock)completionBlock;

- (BOOL)diskImageExistsWithKey:(NSString *)key;

- (NSString *)cachePathForKey:(NSString *)key inPath:(NSString *)inPath;

- (NSString *)defaultCachePathForKey:(NSString *)key;

@end
