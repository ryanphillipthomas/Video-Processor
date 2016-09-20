//
//  SUUploaderViewController.m
//  Death Star Communicator
//
//  Created by Ryan Phillip Thomas on 9/15/16.
//  Copyright © 2016 Ryan Phillip Thomas. All rights reserved.
//

#import "SUUploaderViewController.h"

@interface SUUploaderViewController ()

@end

@implementation SUUploaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateUIWithDefaults];
    [self startMonitoring];
    
    self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height);

    // Do view setup here.
}

- (void)updateUIWithDefaults
{
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"CompressionURL"]) {
        NSURL *compressionURL = [[NSURL alloc] initWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"CompressionURL"]];
        if ([[NSFileManager defaultManager] isReadableFileAtPath:[compressionURL path]] ) {
            [self.compressionLocationLabel setStringValue:[[NSUserDefaults standardUserDefaults] stringForKey:@"CompressionURL"]];
            [self setCompressionURL:compressionURL];
        }
    }
}

- (IBAction)chooseCompressionLocation:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:NO]; // yes if more than one dir is allowed
    
    NSInteger clicked = [panel runModal];
    
    if (clicked == NSFileHandlingPanelOKButton) {
        for (NSURL *url in [panel URLs]) {
            [self.compressionLocationLabel setStringValue:[url absoluteString]];
            self.compressionURL = url;
            [self compressionURLChanged:[url absoluteString]];
            
            [self stopMonitoring];
            [self startMonitoring];
        }
    }
}


- (IBAction)viewOnlineDirectorySelected:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.actorreplay.com/clients/video_uploader/"]];
}

- (void)compressionURLChanged:(NSString *)stringURL
{
    [[NSUserDefaults standardUserDefaults] setObject:stringURL
                                              forKey:@"CompressionURL"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (VPMonitoringController *)monitoringController
{
    if (!_monitoringController) {
        _monitoringController = [[VPMonitoringController alloc] init];
    }
    
    return _monitoringController;
}

- (void)didUpdateFolderStructure {
    //do nothing...
}

- (void)startMonitoring
{
    if ([self fileTransferManagerIsValid]) {
        [self.monitoringIndicator setHidden:NO];
        self.transferStatusLabel.stringValue = @"Ready to upload files...";
        [[self monitoringController] runWithWatchedURL:self.compressionURL];
        [[self monitoringController] setDelegate:self];
        [self.monitoringIndicator startAnimation:self];
        
        self.isMonitoring = YES;
    } else {
        self.transferStatusLabel.stringValue = @"Not ready to upload files...";
        [self.monitoringIndicator setHidden:YES];
        
        self.isMonitoring = NO;
    }
    
}

- (void)stopMonitoring
{
    self.isMonitoring = NO;
    
    self.transferStatusLabel.stringValue = @"Not ready to upload files...";
    
    [self.monitoringIndicator setHidden:YES];
    
    [[self monitoringController] stop];
    
    [[self monitoringController] setDelegate:nil];
}

- (bool)fileTransferManagerIsValid
{
    if (!self.compressionURL || self.compressionLocationLabel.stringValue.length == 0) {
        return NO;
    }
    
    return YES;
}

- (void)didStartUploading:(NSString *)fileName
{
    [self uploadDidStart];
}

- (void)didFinishUploading
{
    [self uploadDidFinish];
}

- (void)uploadDidStart {
    self.transferStatusLabel.stringValue = [NSString stringWithFormat:@"Uploading Files..."];
    
}
- (void)uploadDidFinish{
    self.transferStatusLabel.stringValue = @"Ready to upload files...";
}


@end
