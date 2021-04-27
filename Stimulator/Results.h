//
//  Results.h
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Results : NSObject

- (instancetype)initWithMin:(int)min Max:(int)max;

@property (nonatomic, readonly) int size;

- (void)acquireLock:(void (^)(int * _Nonnull, int, int))lockBlock;
- (unsigned long long)writeValues: (int *)values count:(int)count; // Retval is total number of values written.

@end

NS_ASSUME_NONNULL_END
