//
//  AppDelegate.m
//  VideoProcessor
//
//  Created by Ryan Phillip Thomas on 1/7/16.
//  Copyright © 2016 Ryan Phillip Thomas. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self registerDefaults];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (void)registerDefaults {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"Media Type" : @"",
                                                              @"ScratchURL" : @"",
                                                              @"DeathStarURL" : @"",
                                                              @"Location Name" : @"",
                                                              @"Routine Name" : @"",
                                                              @"CompressionURL" : @""}];
}

@end
