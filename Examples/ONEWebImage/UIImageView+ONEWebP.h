//
//  UIImageView+ONEWebP.h
//  SDWebImage Demo
//
//  Created by Simon on 8/23/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import <UIKit/UIKit.h>

void WebPInitPremultiplyNEON(void);
void WebPInitUpsamplersNEON(void);

@interface UIImageView (ONEWebP)

+ (UIImage *)one_imageWithWebPData:(NSData *)data;

@end
