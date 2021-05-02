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

- (instancetype)initWithMin:(int)min Max:(int)max MaxWriters: (int)max_writers;

@property (nonatomic, readonly) int size;

- (void)readValues:(void (^)(int * _Nonnull, int, int))readBlock;
- (long long)writeValues: (int *)values count:(int)count; // Retval is total number of values written, or -1 in case of error. This is a simple wrapper over acquireLock.

@end

NS_ASSUME_NONNULL_END
