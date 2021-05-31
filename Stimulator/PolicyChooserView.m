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
        int num_policies = sizeof(policies)/sizeof(PolicyFunction);
        for (int i = 0; i < num_policies; i++) {
            PolicyFunction policy_func = policies[i];
            NSButton *button = [NSButton radioButtonWithTitle:[NSString stringWithUTF8String:policy_func.name] target:self action:@selector(buttonPressed:)];
            button.frame = NSMakeRect(0, i*40, 100, 30);
            [button setWantsLayer:YES];
            button.layer.backgroundColor = [NSColor colorWithCalibratedRed:0.87f green:0.22f blue:0.03f alpha:1].CGColor;
            button.layer.cornerRadius = 4;
            button.layer.masksToBounds = true;
            if (policy_func.policy == default_policy) {
                button.state = NSControlStateValueOn;
            }
            [self addSubview:button];
        }

        NSTextField *_policiesLabel = [NSTextField labelWithString:@"Policies"];
        // [_policiesLabel setFont:[NSFont systemFontOfSize:15]];
        printf("num_policies is %d, bigger is %d\n", num_policies, num_policies*40);
        _policiesLabel.frame = NSMakeRect(0, (num_policies*40), 200, 50);
        [self addSubview:_policiesLabel];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
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
