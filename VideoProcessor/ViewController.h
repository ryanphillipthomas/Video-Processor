//
//  ViewController.h
//  VideoProcessor
//
//  Created by Ryan Phillip Thomas on 1/7/16.
//  Copyright © 2016 Ryan Phillip Thomas. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VPMonitoringController.h"
#import "QueueWindowController.h"
#import "FileCopyOperation.h"

@interface ViewController : NSViewController <NSTextFieldDelegate, VPMonitoringDelegate, QueueOperationDelegate>

@property (weak) IBOutlet NSTextField *scratchDiskLocationLabel;
@property (weak) IBOutlet NSTextField *deathStarLocationLabel;
@property (weak) IBOutlet NSTextField *compressionLocationLabel
;
@property (weak) IBOutlet NSPopUpButton *mediaTypeSelector;
@property (weak) IBOutlet NSPopUpButton *qualityTypeSelector;

@property (weak) IBOutlet NSButton *startMonitoringButton;
@property (weak) IBOutlet NSButton *createRoutineSubFolderButton;

@property (weak) IBOutlet NSTextField *locationNameTextField;
@property (weak) IBOutlet NSTextField *routineTextField;

@property (nonatomic, strong) VPMonitoringController *monitoringController;

@property (nonatomic, strong) NSURL *scratchURL;
@property (nonatomic, strong) NSURL *deathStarURL;
@property (nonatomic, strong) NSURL *compressionURL;

@property (nonatomic, strong) NSTimer *timer;
@property (weak) IBOutlet NSProgressIndicator *monitoringIndicator;
@property (weak) IBOutlet NSProgressIndicator *compressionIndicator;

@property (weak) IBOutlet NSTextField *transferStatusLabel;

@property (nonatomic) BOOL isMonitoring;
@end

