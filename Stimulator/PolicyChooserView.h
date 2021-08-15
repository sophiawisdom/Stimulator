//
//  PolicyChooserView.h
//  Stimulator
//
//  Created by Sophia Wisdom on 5/28/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Simul.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PolicyReceiver <NSObject>

- (void)policyChanged: (NSString *)newPolicy;
- (void)addPolicy: (NSString *)policy withCode:(NSString *)code; // add a user-defined policy to the list

@end

@interface PolicyChooserView : NSView

- (instancetype)initWithFrame:(NSRect)frame andDelegate:(id<PolicyReceiver>)delegate;

@end

NS_ASSUME_NONNULL_END
