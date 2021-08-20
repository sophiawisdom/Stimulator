//
//  main.m
//  Stimulator
//
//  Created by Sophia Wisdom on 4/12/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Results.h"

int main(int argc, const char * argv[]) {
    [Results sharedResult]; // this does a fork, and we need the fork to happen before the process becames multithreaded
    // c.f. https://www.mikeash.com/pyblog/friday-qa-2012-01-20-fork-safety.html
    
    return NSApplicationMain(argc, argv);
}
