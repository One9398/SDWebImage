//
//  UIImageView+ONEWebCache.m
//  ONEWebImage
//
//  Created by Simon on 7/10/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import "UIImageView+ONEWebCache.h"
#import "ONEWebImageManager.h"
#import "objc/runtime.h"
#import "UIView+ONEWebChacheOperation.h"

static char imageURLKey;
static char TAG_ACITIVTY_INDICATOR;
static char TAG_ACTIVITY_STYLE;
static char TAG_ACTIVITY_SHOW;

@implementation UIImageView (ONEWebCache)

- (void)one_setImageWithURL:(NSURL *)url {
    [self one_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
    
}

- (void)one_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder {
    [self one_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)one_setImageWithURL:(NSURL *)url completed:(ONEWebImageCompletionBlock)completedBlock {
    [self one_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)one_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(ONEWebImageOptions)options {
    [self one_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
    
}

- (void)one_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(ONEWebImageCompletionBlock)completedBlcok {
    [self one_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlcok];
    
}

- (void)one_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(ONEWebImageOptions)options completed:(ONEWebImageCompletionBlock)completedBlock {
    [self one_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
    
}

- (void)one_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(ONEWebImageOptions)options progress:(ONEWebImageDownloaderProgressBlock)progressBlock completed:(ONEWebImageCompletionBlock)completedBlock {
    [self one_cancelCurrentAnimationImagesLoad];
    objc_setAssociatedObject(self, &imageURLKey, url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (!(options & ONEWebImageDelayPlaceholder)) {
        dispatch_main_async_safe(^{
            self.image = placeholder;            
        })
    }
    
    if (url) {
        
        if ([self p_showActivityIndicatorView]) {
            [self p_addActivityIndicator];
            
        }
        
        __weak typeof(self) weakSelf = self;
        id <ONEWebImageOperation> operation = [[ONEWebImageManager sharedManager] downloadImageWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSError *error, ONEImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            [weakSelf p_removeActivityIndicator];
            if (!weakSelf) return ;
            
            dispatch_main_sync_safe(^{
                if (!weakSelf) return ;
               
                if (image && (options & ONEWebImageAvoidSetImage) && completedBlock) {
                    completedBlock(image, error, cacheType, url);
                    return;
                    
                } else if (image) {
                    weakSelf.image = image;
                    [weakSelf setNeedsLayout];
                    
                } else {
                    if ((options & ONEWebImageDelayPlaceholder)) {
                        weakSelf.image = placeholder;
                        [weakSelf setNeedsLayout];
                        
                    }
                }
                
                if (completedBlock && finished) {
                    completedBlock(image, error, cacheType, url);
                    
                }
                
            });
            
        }];
        
        [self one_setImageLoadOperation:operation forKey:@"UIImageViewImageLoad"];
        
    } else {
        dispatch_main_async_safe(^{
            [self p_removeActivityIndicator];
            
            if (completedBlock) {
                NSError *error = [NSError errorWithDomain:ONEWebImageErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Trying tp load a nil url"}];
                completedBlock(nil, error, ONEImageCacheTypeNone, url);
                
            }
        });
    }
}

- (void)one_setImageWithPreviousCachedImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(ONEWebImageOptions)options progress:(ONEWebImageDownloaderProgressBlock)progressBlock completed:(ONEWebImageCompletionBlock)completedBlock {
    NSString *key = [[ONEWebImageManager sharedManager] cacheKeyForURL:url];
    UIImage *lastPerviousImage = [[ONEImageCache sharedImageCache] imageFromDiskCacheForKey:key];
    
    [self one_setImageWithURL:url placeholderImage:lastPerviousImage ?: placeholder options:options progress:progressBlock completed:completedBlock];
}

- (NSURL *)one_imageURL {
    return objc_getAssociatedObject(self, &imageURLKey);
    
}

- (void)one_setAnimationImagesWithURLs:(NSArray *)arrayOfURLs {
    [self one_cancelCurrentAnimationImagesLoad];
    __weak typeof(self) weakSelf = self;
    
    NSMutableArray *operations = [NSMutableArray array];
    
    for (NSURL *logoImageURL in arrayOfURLs) {
        id <ONEWebImageOperation> operation = [[ONEWebImageManager sharedManager] downloadImageWithURL:logoImageURL options:0 progress:nil completed:^(UIImage *image, NSError *error, ONEImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (!weakSelf) return ;
            dispatch_main_sync_safe(^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return ;
                [strongSelf stopAnimating];
                if (strongSelf && image) {
                    NSMutableArray *currentImages = [[strongSelf animationImages] mutableCopy];
                    if (!currentImages) {
                        currentImages = [NSMutableArray array];
                        
                    }
                    [currentImages addObject:image];
                    strongSelf.animationImages = currentImages;
                    [strongSelf setNeedsLayout];
                    
                }
                
                [strongSelf startAnimating];
            });
        }];
        
        [operations addObject:operation];
        
    }
    
    [self one_setImageLoadOperation:[NSArray arrayWithArray:operations] forKey:@"UIImageViewAnimationImages"];
    
}

- (void)one_cancelCurrentAnimationImagesLoad {
    [self one_cancelImageLoadOperationWithKey:@"UIImageViewAnimationImageLoads"];
    
}

- (void)one_cancelCurrentImageLoad {
    [self one_cancelImageLoadOperationWithKey:@"UIImageViewImageLoad"];
    
}

- (void)one_setShowActivityIndicatorView:(BOOL)show {
    objc_setAssociatedObject(self, &TAG_ACTIVITY_SHOW, [NSNumber numberWithBool:show], OBJC_ASSOCIATION_RETAIN);
    
}

- (void)one_setIndicatorStyle:(UIActivityIndicatorViewStyle)style {
    objc_setAssociatedObject(self, &TAG_ACTIVITY_STYLE, [NSNumber numberWithInt:style], OBJC_ASSOCIATION_RETAIN);
    
}

#pragma mark -
- (UIActivityIndicatorView *)activityIndicator {
    return (UIActivityIndicatorView *)objc_getAssociatedObject(self, &TAG_ACITIVTY_INDICATOR);
}

- (void)setActivityIndicator:(UIActivityIndicatorView *)activityIndicator {
    objc_setAssociatedObject(self, &TAG_ACITIVTY_INDICATOR, activityIndicator, OBJC_ASSOCIATION_RETAIN);
    
}

- (void)p_addActivityIndicator {
    if (!self.activityIndicator) {
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[self p_getIndicatorStyle]];
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NSNotFound;
        dispatch_main_async_safe(^{
            [self addSubview:self.activityIndicator];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
            
        })
    }
    
    dispatch_main_async_safe(^{
        [self.activityIndicator startAnimating];
        
    })
}

- (void)p_removeActivityIndicator {
    if (self.activityIndicator) {
        [self.activityIndicator removeFromSuperview];
        self.activityIndicator = nil;
    }
}

- (BOOL)p_showActivityIndicatorView {
    return [objc_getAssociatedObject(self, &TAG_ACTIVITY_SHOW) boolValue];
    
}

- (int)p_getIndicatorStyle {
    return [objc_getAssociatedObject(self, &TAG_ACTIVITY_STYLE) intValue];
    
}

@end
