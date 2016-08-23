//
//  UIImage+ONEGIF.h
//  SDWebImage Demo
//
//  Created by Simon on 8/23/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ONEGIF)

+ (UIImage *)one_animatedGIFNamed:(NSString *)name;
+ (UIImage *)one_animatedGIFData:(NSData *)data;

- (UIImage *)one_animatedImageByScalingAndCroppingToSize:(CGSize)size;

@end
