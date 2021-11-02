//
//  ParamsChooserView.m
//  Stimulator
//
//  Created by Sophia Wisdom on 5/30/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "ParamsChooserView.h"

@implementation ParamsChooserView {
    id<ParamsReceiver> _delegate;
    Parameters _params;
    NSString *_policy_name;

    NSSlider *_blocksHigh;
    NSSlider *_blocksWide;
    NSSlider *_blockHeight;
    NSSlider *_blockWidth;
    NSSlider *_stoplightTime;
    NSSlider *_streetWidth;
    PolicyChooserView *_policyChooserView;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    // Drawing code here.
}

// TODO: HAVE THESE SAME SLIDERS FOR THE BLOCK VIEW SO PEOPLE SEE WHAT'S CHANGING

- (instancetype)initWithFrame:(NSRect)frame andDelegate:(id<ParamsReceiver>)delegate;
{
    printf("ParamsChooserView got initWithFrame andDelegate\n");
    if (self = [super initWithFrame:frame]) {
        _delegate = delegate;
        memcpy(&_params, &default_params, sizeof(Parameters));
        
        /*
        blocks_wide = blocksWide;
        params -> blocks_high = blocksHigh;
        params -> block_height = blockHeight;
        params -> block_width = blockWidth;
        params -> stoplight_time = stoplightTime;
        params -> street_width = streetWidth;
        params -> policy
        */
        _blocksWide = [[NSSlider alloc] initWithFrame:NSMakeRect(20, 20, 100, 20)];
        _blocksWide.continuous = YES;
        _blocksWide.minValue = 1;
        _blocksWide.maxValue = 100; // We don't need tickmarks because the number is so high, we'll just cast to integer when it's changed.
        _blocksWide.target = self;
        _blocksWide.action = @selector(blocksWideChanged);
        _blocksWide.intValue = default_params.blocks_wide;
        NSTextField *_blocksWideLabel = [NSTextField labelWithString:@"Blocks Wide"];
        _blocksWideLabel.frame = NSMakeRect(20, 45, 100, 20);
        _blocksWideLabel.alignment = NSTextAlignmentCenter;
        [self addSubview:_blocksWide];
        [self addSubview:_blocksWideLabel];

        _blocksHigh = [[NSSlider alloc] initWithFrame:NSMakeRect(20, 70, 100, 20)];
        _blocksHigh.continuous = YES;
        _blocksHigh.minValue = 1;
        _blocksHigh.maxValue = 100; // We don't need tickmarks because the number is so high, we'll just cast to integer when it's changed.
        _blocksHigh.target = self;
        _blocksHigh.action = @selector(blocksHighChanged);
        _blocksHigh.intValue = default_params.blocks_high;
        NSTextField *_blocksHighLabel = [NSTextField labelWithString:@"Blocks High"];
        _blocksHighLabel.frame = NSMakeRect(20, 95, 100, 20);
        _blocksHighLabel.alignment = NSTextAlignmentCenter;
        [self addSubview:_blocksHigh];
        [self addSubview:_blocksHighLabel];
        
        _blockHeight = [[NSSlider alloc] initWithFrame:NSMakeRect(20, 120, 100, 20)];
        _blockHeight.continuous = YES;
        _blockHeight.minValue = 5;
        _blockHeight.maxValue = 100; // We don't need tickmarks because the number is so high, we'll just cast to integer when it's changed.
        _blockHeight.target = self;
        _blockHeight.action = @selector(blockHeightChanged);
        _blockHeight.floatValue = default_params.block_height;
        NSTextField *_blockHeightLabel = [NSTextField labelWithString:@"Block Height"];
        _blockHeightLabel.frame = NSMakeRect(20, 145, 100, 20);
        _blockHeightLabel.alignment = NSTextAlignmentCenter;
        [self addSubview:_blockHeight];
        [self addSubview:_blockHeightLabel];
        
        _blockWidth = [[NSSlider alloc] initWithFrame:NSMakeRect(20, 170, 100, 20)];
        _blockWidth.continuous = YES;
        _blockWidth.minValue = 5;
        _blockWidth.maxValue = 100; // We don't need tickmarks because the number is so high, we'll just cast to integer when it's changed.
        _blockWidth.target = self;
        _blockWidth.action = @selector(blockWidthChanged);
        _blockWidth.floatValue = default_params.block_width;
        NSTextField *_blockWidthLabel = [NSTextField labelWithString:@"Block Width"];
        _blockWidthLabel.frame = NSMakeRect(20, 195, 100, 20);
        _blockWidthLabel.alignment = NSTextAlignmentCenter;
        [self addSubview:_blockWidth];
        [self addSubview:_blockWidthLabel];
        
        _stoplightTime = [[NSSlider alloc] initWithFrame:NSMakeRect(20, 220, 100, 20)];
        _stoplightTime.continuous = YES;
        _stoplightTime.minValue = 1;
        _stoplightTime.maxValue = 20; // We don't need tickmarks because the number is so high, we'll just cast to integer when it's changed.
        _stoplightTime.target = self;
        _stoplightTime.action = @selector(stoplightTimeChanged);
        _stoplightTime.floatValue = default_params.stoplight_time;
        NSTextField *_stoplightTimeLabel = [NSTextField labelWithString:@"Stoplight Time"];
        _stoplightTimeLabel.frame = NSMakeRect(20, 245, 100, 20);
        _stoplightTimeLabel.alignment = NSTextAlignmentCenter;
        [self addSubview:_stoplightTime];
        [self addSubview:_stoplightTimeLabel];
        
        _streetWidth = [[NSSlider alloc] initWithFrame:NSMakeRect(20, 270, 100, 20)];
        _streetWidth.continuous = YES;
        _streetWidth.minValue = 0;
        _streetWidth.maxValue = 5; // We don't need tickmarks because the number is so high, we'll just cast to integer when it's changed.
        _streetWidth.target = self;
        _streetWidth.action = @selector(streetWidthChanged);
        _streetWidth.floatValue = default_params.street_width;
        NSTextField *_streetWidthLabel = [NSTextField labelWithString:@"Street Width"];
        _streetWidthLabel.frame = NSMakeRect(20, 295, 100, 20);
        _streetWidthLabel.alignment = NSTextAlignmentCenter;
        [self addSubview:_streetWidth];
        [self addSubview:_streetWidthLabel];
        
        _policyChooserView = [[PolicyChooserView alloc] initWithFrame:NSMakeRect(200, 20, 400, 300) andDelegate:self];
        _policy_name = @"default_policy";
        [self addSubview:_policyChooserView];

        self.wantsLayer = YES;
        self.layer.backgroundColor = [NSColor colorWithDeviceRed:0.18 green:.35 blue:.2 alpha:1].CGColor;
        self.layer.cornerRadius = 30;
        self.layer.masksToBounds = true;
    }
    return self;
}

- (void)update_params {
    [_delegate setParams:[[ParametersObject alloc] initWithBlocksWide:_params.blocks_wide blocksHigh:_params.blocks_high blockHeight:_params.block_height blockWidth:_params.block_width stoplightTime:_params.stoplight_time streetWidth:_params.street_width policy:_params.policy policyName:_policy_name]];
}

- (void)streetWidthChanged {
    if (_params.street_width != [_streetWidth floatValue]) {
        _params.street_width = [_streetWidth floatValue];
        [self update_params];
    }
}

- (void)stoplightTimeChanged {
    if (_params.stoplight_time != [_stoplightTime floatValue]) {
        _params.stoplight_time = [_stoplightTime floatValue];
        [self update_params];
    }
}

- (void)blockWidthChanged {
    if (_params.block_width != [_blockWidth floatValue]) {
        _params.block_width = [_blockWidth floatValue];
        [self update_params];
    }
}

- (void)blockHeightChanged {
    if (_params.block_height != [_blockHeight floatValue]) {
        _params.block_height = [_blockHeight floatValue];
        [self update_params];
    }
}

- (void)blocksHighChanged {
    if (_params.blocks_high != [_blocksHigh intValue]) {
        _params.blocks_high = [_blocksHigh intValue];
        // printf("set blocks_high to %d\n", _params.blocks_high);
        [self update_params];
    }
}

- (void)blocksWideChanged {
    if (_params.blocks_wide != [_blocksWide intValue]) {
        _params.blocks_wide = [_blocksWide intValue];
        // printf("set blocks_wide to %d\n", _params.blocks_wide);
        [self update_params];
    }
}

- (void)changeActivePolicy:(nonnull NSString *)newPolicy {
    if (![_policy_name isEqualToString:newPolicy]) {
        _policy_name = newPolicy;
        [self update_params];
    }
}

- (void)addPolicy:(NSString *)policy withCode:(NSString *)code {
    _policy_name = policy;
    [_delegate addPolicy:policy withCode:code];
    [self update_params];
}

@end
