//
//  UIView+ONEWebChacheOperation.m
//  SDWebImage
//
//  Created by Simon on 7/10/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import "UIView+ONEWebChacheOperation.h"
#import "objc/runtime.h"

static char loadOperationKey;

@implementation UIView (ONEWebChacheOperation)

- (NSMutableDictionary *)operationDictionary {
    NSMutableDictionary *operations = objc_getAssociatedObject(self, &loadOperationKey);
    if (operations) {
        return operations;
        
    }
    
    operations = [NSMutableDictionary dictionary];
    objc_setAssociatedObject(self, &loadOperationKey, operations, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return operations;
}

- (void)one_setImageLoadOperation:(id)operation forKey:(NSString *)key {
    [self one_cancelImageLoadOperationWithKey:key];
    NSMutableDictionary *operationDictionary = [self operationDictionary];
    [operationDictionary setObject:operation forKey:key];
    
}

- (void)one_cancelImageLoadOperationWithKey:(NSString *)key {
    NSMutableDictionary *operationDictionary = [self operationDictionary];
    id operations = [operations objectForKey:key];

    if (operations) {
        if ([operations isKindOfClass:[NSArray class]]) {
            for (id <ONEWebImageOperation> operation in operations) {
                if (operation) {
                    [operation cancel];
                }
            }
        } else if ([operations conformsToProtocol:@protocol(ONEWebImageOperation)]) {
            [(id <ONEWebImageOperation>)operations cancel];
        }

        [operationDictionary removeObjectForKey:key];
        
    }
}

- (void)one_removeImageLoadOperationWithKey:(NSString *)key {
    NSMutableDictionary *operations = [self operationDictionary];
    [operations removeObjectForKey:key];
}

@end
