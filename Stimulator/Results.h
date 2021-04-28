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

// - (void)acquireLock:(void (^)(float * _Nonnull, int, int, long long))lockBlock;
- (void)readValues:(void (^)(float * _Nonnull, int, int, long long))readBlock;
- (long long)writeValues: (float *)values count:(int)count; // Retval is total number of values written, or -1 in case of error. This is a simple wrapper over acquireLock.

@end

NS_ASSUME_NONNULL_END
