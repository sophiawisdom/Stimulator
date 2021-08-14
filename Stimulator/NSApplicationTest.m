//
//  NSApplicationTest.m
//  Stimulator
//
//  Created by Sophia Wisdom on 8/11/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "NSApplicationTest.h"
#import "AppDelegate.h"
#import "RealtimeGraphController.h"

@implementation NSApplicationTest {
    AppDelegate *_thing;
    NSWindow *_window;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        printf("NSApplicationTest initialized\n");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            printf("Setting delegate...\n");
            NSLog(@"%@ %@", self.mainWindow, self.keyWindow);
            self -> _thing = [[AppDelegate alloc] init];
            self.delegate = self -> _thing;
            _window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, NSScreen.mainScreen.frame.size.width, NSScreen.mainScreen.frame.size.height) styleMask:NSWindowStyleMaskMiniaturizable&NSWindowStyleMaskResizable&NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:false];
            [_window makeKeyAndOrderFront:nil];
            _window.title = @"Stimulation for the Mind";
            // _window.contentView = [[TestView alloc] init];
            NSLog(@"birth window is %@", _window);
            _window.contentViewController = [[RealtimeGraphController alloc] initWithFrame:_window.frame];
        });
    }
    return self;
}

@end
