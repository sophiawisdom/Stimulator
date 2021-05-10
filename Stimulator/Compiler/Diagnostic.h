//
//  Diagnostic.h
//  Stimulator
//
//  Created by Sophia Wisdom on 5/9/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../libclang/Index.h"

NS_ASSUME_NONNULL_BEGIN

@interface Diagnostic : NSObject

@property NSString *str;
@property unsigned int line;
@property unsigned int column;
@property enum CXDiagnosticSeverity severity;

@end

NS_ASSUME_NONNULL_END
