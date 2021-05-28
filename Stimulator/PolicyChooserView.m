//
//  PolicyChooserView.m
//  Stimulator
//
//  Created by Sophia Wisdom on 5/28/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "PolicyChooserView.h"
#import "Simul.h"
#import <objc/runtime.h>

@implementation PolicyChooserView {
    id<PolicyReceiver> _delegate;
}

- (instancetype)initWithFrame:(NSRect)frame andDelegate:(id<PolicyReceiver>)delegate;
{
    if (self = [super initWithFrame:frame]) {
        _delegate = delegate;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
        
    for (int i = 0; i < sizeof(policies)/sizeof(PolicyFunction); i++) {
        PolicyFunction policy_func = policies[i];
        NSButton *button = [NSButton radioButtonWithTitle:[NSString stringWithUTF8String:policy_func.name] target:self action:@selector(buttonPressed:)];
        button.frame = NSMakeRect(0, 0 + (i*40), 100, 30);
        [button setWantsLayer:YES];
        button.layer.backgroundColor = [NSColor colorWithCalibratedRed:0.121f green:0.4375f blue:0.1992f alpha:0.2578f].CGColor;
        [self addSubview:button];
    }
    // Drawing code here.
}

- (void)buttonPressed: (NSButton *)buttonPressed {
    for (int i = 0; i < sizeof(policies)/sizeof(PolicyFunction); i++) {
        if ([buttonPressed.title isEqualToString:[NSString stringWithUTF8String:policies[i].name]]) {
            [_delegate policyChanged:policies[i].policy];
            return;
        }
    }
    
    NSLog(@"Unable to find policy for button %@ with title %@", buttonPressed, buttonPressed.title);
}

@end
