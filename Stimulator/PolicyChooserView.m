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
        int num_policies = sizeof(policies)/sizeof(char *);
        for (int i = 0; i < num_policies; i++) {
            NSButton *button = [NSButton radioButtonWithTitle:[NSString stringWithUTF8String:policies[i]] target:self action:@selector(buttonPressed:)];
            button.frame = NSMakeRect(0, i*40, 100, 30);
            [button setWantsLayer:YES];
            button.layer.backgroundColor = [NSColor colorWithCalibratedRed:0.87f green:0.22f blue:0.03f alpha:1].CGColor;
            button.layer.cornerRadius = 4;
            button.layer.masksToBounds = true;
            if (strcmp(policies[i], "default_policy") == 0) {
                button.state = NSControlStateValueOn;
            }
            [self addSubview:button];
        }

        NSTextField *_policiesLabel = [NSTextField labelWithString:@"Policies"];
        // [_policiesLabel setFont:[NSFont systemFontOfSize:15]];
        _policiesLabel.frame = NSMakeRect(0, (num_policies*40), 200, 50);
        [self addSubview:_policiesLabel];
        
        NSTextView *_blah = [[NSTextView alloc] initWithFrame:NSMakeRect(100, 0, 200, 50)];
        [self addSubview:_blah];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    // Drawing code here.
}

- (void)buttonPressed: (NSButton *)buttonPressed {
    [_delegate policyChanged:buttonPressed.title];
}

@end
