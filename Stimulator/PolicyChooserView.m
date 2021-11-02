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
#include <sys/stat.h>

@implementation PolicyChooserView {
    id<PolicyReceiver> _delegate;
    
    NSTextField *_function_name;
    NSTextView *_codeInput;
    NSButton *_codeButton;
    
    int _symbol_number;
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
        
        _codeButton = [[NSButton alloc] initWithFrame:NSMakeRect(100, 0, 100, 30)];
        [_codeButton setTarget:self];
        [_codeButton setAction:@selector(codeButton:)];
        _codeButton.title = @"code";
        [self addSubview:_codeButton];
        
        _symbol_number = 0;
        
        
        /*
        _codeInput = [[NSTextView alloc] initWithFrame:NSMakeRect(100, 0, 200, 50)];
        [_codeInput setDelegate:self];
        [self addSubview:_codeInput];
         */
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    // Drawing code here.
}

- (void)buttonPressed: (NSButton *)buttonPressed {
    [_delegate changeActivePolicy:buttonPressed.title];
}

- (void)codeButton: (NSButton *)button {
    int fd = open("/users/sophiawisdom/blahgah.c", O_RDONLY);
    struct stat stats;
    fstat(fd, &stats);
    char *buffer = malloc(stats.st_size + 50);
    memset(buffer, 0, stats.st_size + 50);
    read(fd, buffer, stats.st_size);
    printf("buffer is %s\n", buffer);
    NSString *name = [NSString stringWithFormat:@"policy_%d", _symbol_number++];
    NSString *func = [NSString stringWithFormat:@"PolicyResult %@(struct simul * current_state) {%s}", name, buffer];
    NSLog(@"func is %@", func);
    [_delegate addPolicy:name withCode:func];
    free(buffer);
    close(fd);
}

@end
