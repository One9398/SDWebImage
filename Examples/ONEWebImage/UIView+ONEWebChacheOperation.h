//
//  UIView+ONEWebChacheOperation.h
//  SDWebImage
//
//  Created by Simon on 7/10/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ONEWebImageManager.h"

@interface UIView (ONEWebChacheOperation)

- (void)one_setImageLoadOperation:(id)operation forKey:(NSString *)key;

- (void)one_cancelImageLoadOperationWithKey:(NSString *)key;

- (void)one_removeImageLoadOperationWithKey:(NSString *)key;

@end
