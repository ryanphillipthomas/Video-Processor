//
//  SUUploaderViewController.h
//  Death Star Communicator
//
//  Created by Ryan Phillip Thomas on 9/15/16.
//  Copyright © 2016 Ryan Phillip Thomas. All rights reserved.
//

#import "ViewController.h"
#import "VPMonitoringController.h"

@interface SUUploaderViewController : NSViewController <VPMonitoringDelegate>

@property (nonatomic, strong) VPMonitoringController *monitoringController;

@property (weak) IBOutlet NSTextField *compressionLocationLabel;
@property (nonatomic, strong) NSURL *compressionURL;
@property (weak) IBOutlet NSTextField *transferStatusLabel;

@property (nonatomic) BOOL isMonitoring;

@property (weak) IBOutlet NSProgressIndicator *monitoringIndicator;
@property (weak) IBOutlet NSProgressIndicator *compressionIndicator;

@end
