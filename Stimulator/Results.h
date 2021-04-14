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

@property (nonatomic) int size;

- (void)acquireLock:(void (^)(int * _Nonnull, int, int))lockBlock;

@end

NS_ASSUME_NONNULL_END
