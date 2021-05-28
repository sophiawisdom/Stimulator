//
//  AppDelegate.m
//  Stimulator
//
//  Created by Sophia Wisdom on 4/12/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "AppDelegate.h"
#import "RealtimeGraphController.h"
#import <MetalKit/MetalKit.h>

@interface AppDelegate ()

@end

@implementation AppDelegate {
    NSWindow *_window;
}
    // NSWindow *_window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // NSWindowStyleMask mask = NSWindowStyleMaskMiniaturizable & NSWindowStyleMaskResizable & NSWindowStyleMaskClosable;
    printf("About to create window...\n");
    _window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, NSScreen.mainScreen.frame.size.width, NSScreen.mainScreen.frame.size.height) styleMask:NSWindowStyleMaskMiniaturizable&NSWindowStyleMaskResizable&NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:false];
    [_window makeKeyAndOrderFront:nil];
    _window.title = @"Stimulation for the Mind";
    // _window.contentView = [[TestView alloc] init];
    NSLog(@"birth window is %@", _window);
    _window.contentViewController = [[RealtimeGraphController alloc] initWithFrame:_window.frame];
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    NSLog(@"death window is %@", _window);
}


@end
