//
//  PXViewController.m
//  prebid-blocking
//
//  Created by Pixalate on 11/23/2021.
//  Copyright (c) 2021 Pixalate. All rights reserved.
//

#import "PXViewController.h"
#import <PXBlocking.h>

@interface PXViewController ()

@end

@implementation PXViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSLog( @"Starting up!" );
    
    PXGlobalConfig *config = [PXGlobalConfig makeWithApiKey:@"some-api-key" builder:^(PXGlobalConfigBuilder *builder) {
        builder.threshold = 0.75;
        builder.timeoutInterval = 3;
    }];
    
    [PXBlocking setGlobalConfig:config];
    [PXBlocking setLogLevel:PXLogLevelDebug];
    
    [PXBlocking requestBlockStatus:^(BOOL block, NSError * _Nullable error) {
        NSLog( @"Error: %@", error );
        NSLog( @"Block: %d", block );
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
