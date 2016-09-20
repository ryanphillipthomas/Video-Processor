//
//  ViewController.m
//  VideoProcessor
//
//  Created by Ryan Phillip Thomas on 1/7/16.
//  Copyright © 2016 Ryan Phillip Thomas. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
QueueWindowController * _queueWindowController;

- (void)didStartUploading:(NSString *)fileName
{
//do nothing
}

- (void)didFinishUploading
{
//do nothing
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateUIWithDefaults];
    [self startMonitoring];
    
    self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height);

}

- (void)viewWillDisappear
{
    [self stopMonitoring];
}

- (IBAction)viewTransferQue:(id)sender {
    // ----------------------------------------------------------------------------------------------------
    // This is some lazy instantiation for the _queueWindorController
    // ----------------------------------------------------------------------------------------------------
    if (!_queueWindowController) {
        _queueWindowController = [[QueueWindowController alloc]initWithWindowNibName:@"Queue"];
        [_queueWindowController setDelegate:self];
    }
    
        [_queueWindowController showWindow:nil];
    
    // ----------------------------------------------------------------------------------------------------
    // Do your checks here, check if the file already exists and handle if the file should be
    // overwritten, or renamed.
    // Beyond this point [addFileCopyOperationWithSource:andDestination:] will only check if the urls are
    // reachable, if the file urls can be reached the operation will be queued.
    // ----------------------------------------------------------------------------------------------------
}

- (void)didAddFileToQueSourceURL:(NSURL *)sourceURL andDestination:(NSURL *)destinationURL
{
//    [self.transferStatusLabel setStringValue:[NSString stringWithFormat:@"Did Add %@", fileName]];
    
    // ----------------------------------------------------------------------------------------------------
    // This is some lazy instantiation for the _queueWindorController
    // ----------------------------------------------------------------------------------------------------
    if (!_queueWindowController) {
        _queueWindowController = [[QueueWindowController alloc]initWithWindowNibName:@"Queue"];
        [_queueWindowController setDelegate:self];
        [_queueWindowController lazyLoad];
    }
    
    [_queueWindowController addFileCopyOperationWithSource:sourceURL andDestination:destinationURL];
}

- (void)didUpdateCompressionValue:(NSNumber *)value
{
    if (value.integerValue > 0) {
        [self.compressionStatusLabel setHidden:YES];
    } else {
        [self.compressionStatusLabel setHidden:NO];
    }
}

- (void)didErrorFile:(NSString *)fileName
{
    [self updateMonitoringStatusState:fileName];
}

- (void)updateUIWithDefaults
{
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"ScratchURL"]) {
        NSURL *scratchURL = [[NSURL alloc] initWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"ScratchURL"]];
        if ([[NSFileManager defaultManager] isReadableFileAtPath:[scratchURL path]] ) {
            [self.scratchDiskLocationLabel setStringValue:[[NSUserDefaults standardUserDefaults] stringForKey:@"ScratchURL"]];
            [self setScratchURL:scratchURL];
        }
    }
    
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"DeathStarURL"]) {
        NSURL *deathStarURL = [[NSURL alloc] initWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"DeathStarURL"]];
        if ([[NSFileManager defaultManager] isReadableFileAtPath:[deathStarURL path]] ) {
            [self.deathStarLocationLabel setStringValue:[[NSUserDefaults standardUserDefaults] stringForKey:@"DeathStarURL"]];
            [self setDeathStarURL:deathStarURL];
        }
    }
    
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"CompressionURL"]) {
        NSURL *compressionURL = [[NSURL alloc] initWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"CompressionURL"]];
        if ([[NSFileManager defaultManager] isReadableFileAtPath:[compressionURL path]] ) {
            [self.compressionLocationLabel setStringValue:[[NSUserDefaults standardUserDefaults] stringForKey:@"CompressionURL"]];
            [self setCompressionURL:compressionURL];
        }
    }
    
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"Location Name"]) {
        [self.locationNameTextField setStringValue:[[NSUserDefaults standardUserDefaults] stringForKey:@"Location Name"]];
    }
    
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"Routine Name"]) {
        [self.routineTextField setStringValue:[[NSUserDefaults standardUserDefaults] stringForKey:@"Routine Name"]];
    }
    
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"Media Type"]) {
        if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"Media Type"] isEqualToString:@"Video"]) {
            [self.mediaTypeSelector selectItemAtIndex:0];
        } else if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"Media Type"] isEqualToString:@"Photo"]) {
            [self.mediaTypeSelector selectItemAtIndex:1];
        }
    }
    
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"Quality Type"]) {
        if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"Quality Type"] isEqualToString:@"High Quality Only"]) {
            [self.qualityTypeSelector selectItemAtIndex:0];
        } else if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"Quality Type"] isEqualToString:@"Compressed Only"]) {
            [self.qualityTypeSelector selectItemAtIndex:1];
        } else if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"Quality Type"] isEqualToString:@"High Quality & Compressed"]) {
            [self.qualityTypeSelector selectItemAtIndex:2];
        }
    }
    
    [self updateRoutineSubFolderButtonEnabledState];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)controlTextDidChange:(NSNotification *)notification {
    [self locationNameChanged:self.locationNameTextField.stringValue];
    [self routineNameChanged:self.routineTextField.stringValue];
    [self updateRoutineSubFolderButtonEnabledState];
    
    if (![self shouldEnableRoutineSubFolderButton]) {
        if (!self.isMonitoring) {
            [self startMonitoring];
        }
    }
}

- (void)updateRoutineSubFolderButtonEnabledState
{
    if ([self shouldEnableRoutineSubFolderButton]) {
        [self.createRoutineSubFolderButton setEnabled:YES];
    } else {
        [self.createRoutineSubFolderButton setEnabled:NO];
    }
}

- (bool)shouldEnableRoutineSubFolderButton
{
    if ([[NSFileManager defaultManager] isReadableFileAtPath:[[self routineSubfolderURL] path]] ) {
        return NO;
    } else {
        if (self.locationNameTextField.stringValue.length == 0 || self.routineTextField.stringValue.length == 0) {
            return NO;
        } else {
            return YES;
        }
    }
    
    return NO;
}

- (IBAction)triggerMediaUpdate:(id)sender {
    [self mediaTypeChanged:self.mediaTypeSelector.selectedItem.title];
    [self updateRoutineSubFolderButtonEnabledState];
    
    [self stopMonitoring];
    
    if (![self shouldEnableRoutineSubFolderButton]) {
        if (!self.isMonitoring) {
            [self startMonitoring];
        }
    }
}

//not finished // but partially hooked up // need to investigate monitoring states
- (IBAction)triggerQualityUpdate:(id)sender {
    [self qualityTypeChanged:self.qualityTypeSelector.selectedItem.title];
    [self updateRoutineSubFolderButtonEnabledState];
    
    [self stopMonitoring];
    
    if (![self shouldEnableRoutineSubFolderButton]) {
        if (!self.isMonitoring) {
            [self startMonitoring];
        }
    }
}

- (void)didUpdateFolderStructure {
    [self updateRoutineSubFolderButtonEnabledState];
}

- (IBAction)chooseScratchLocation:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:NO]; // yes if more than one dir is allowed
    
    NSInteger clicked = [panel runModal];
    
    if (clicked == NSFileHandlingPanelOKButton) {
        for (NSURL *url in [panel URLs]) {
            [self.scratchDiskLocationLabel setStringValue:[url absoluteString]];
            self.scratchURL = url;
            [self scratchURLChanged:[url absoluteString]];
            
            [self stopMonitoring];
            
            if (![self shouldEnableRoutineSubFolderButton]) {
                [self startMonitoring];
            }
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
            
            if (![self shouldEnableRoutineSubFolderButton]) {
                [self startMonitoring];
            }
        }
    }
}

- (IBAction)chooseDeathStar:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:NO]; // yes if more than one dir is allowed
    
    NSInteger clicked = [panel runModal];
    
    if (clicked == NSFileHandlingPanelOKButton) {
        for (NSURL *url in [panel URLs]) {
            [self.deathStarLocationLabel setStringValue:[url absoluteString]];
            self.deathStarURL = url;
            [self deathStarURLChanged:[url absoluteString]];
            
            [self stopMonitoring];
            
            if (![self shouldEnableRoutineSubFolderButton]) {
                [self startMonitoring];
            }
        }
    }
}

- (IBAction)createRoutineSubfolder:(id)sender {
    [self addNewRoutineSubfolder];
}

- (void)addNewRoutineSubfolder
{
    __block NSURL *blockDestinationURL = self.scratchURL;
    __block NSString *blockRoutineName = self.routineTextField.stringValue;
    __block NSString *blockMediaType = self.mediaTypeSelector.selectedItem.title;
    __block NSString *blockLocationName = self.locationNameTextField.stringValue;
    
    NSOperationQueue *myQueue = [[NSOperationQueue alloc] init];
    [myQueue addOperationWithBlock:^{
        if ([[NSFileManager defaultManager] isReadableFileAtPath:[blockDestinationURL path]] ) {
            
            NSString *folderName = [NSString stringWithFormat:@"%@ - %@", blockRoutineName, blockMediaType];
            
            if (blockLocationName) {
                blockDestinationURL = [blockDestinationURL URLByAppendingPathComponent:blockLocationName];
            }
            
            if (blockRoutineName) {
                blockDestinationURL = [blockDestinationURL URLByAppendingPathComponent:folderName];
            }
            
            NSFileManager *fileManager= [NSFileManager defaultManager];
            NSError *error = nil;
            
            if(![fileManager createDirectoryAtPath:[blockDestinationURL path] withIntermediateDirectories:YES attributes:nil error:&error]) {
                // An error has occurred, do something to handle it
                NSLog(@"Failed to create directory \"%@\". Error: %@", [blockDestinationURL path], error);
            }
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self updateRoutineSubFolderButtonEnabledState];
                
                if (!self.isMonitoring) {
                    [self startMonitoring];
                }
            }];
        }
    }];
}

- (NSURL *)routineSubfolderURL
{
    __block NSURL *blockDestinationURL = self.scratchURL;
    __block NSString *blockRoutineName = self.routineTextField.stringValue;
    __block NSString *blockMediaType = self.mediaTypeSelector.selectedItem.title;
    __block NSString *blockLocationName = self.locationNameTextField.stringValue;
    
    NSString *folderName = [NSString stringWithFormat:@"%@ - %@", blockRoutineName, blockMediaType];
    
    if (blockLocationName) {
        blockDestinationURL = [blockDestinationURL URLByAppendingPathComponent:blockLocationName];
    }
    
    if (blockRoutineName) {
        blockDestinationURL = [blockDestinationURL URLByAppendingPathComponent:folderName];
    }
    
    return blockDestinationURL;
}

- (void)compressionURLChanged:(NSString *)stringURL
{
    [[NSUserDefaults standardUserDefaults] setObject:stringURL
                                              forKey:@"CompressionURL"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)scratchURLChanged:(NSString *)stringURL
{
    [[NSUserDefaults standardUserDefaults] setObject:stringURL
                                              forKey:@"ScratchURL"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)deathStarURLChanged:(NSString *)stringURL
{
    [[NSUserDefaults standardUserDefaults] setObject:stringURL
                                              forKey:@"DeathStarURL"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)routineNameChanged:(NSString *)string
{
    [[NSUserDefaults standardUserDefaults] setObject:string
                                              forKey:@"Routine Name"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)mediaTypeChanged:(NSString *)string
{
    [[NSUserDefaults standardUserDefaults] setObject:string
                                              forKey:@"Media Type"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)qualityTypeChanged:(NSString *)string
{
    [[NSUserDefaults standardUserDefaults] setObject:string
                                              forKey:@"Quality Type"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)locationNameChanged:(NSString *)string
{
    [[NSUserDefaults standardUserDefaults] setObject:string
                                              forKey:@"Location Name"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


//- (IBAction)startMonitoring:(id)sender {
//    if (self.scratchURL) {
//        if (!self.isMonitoring) {
//            //start
//            self.isMonitoring = YES;
//            self.startMonitoringButton.title = @"Stop Monitoring";
//            
//            [[self monitoringController] runWithWatchedURL:self.scratchURL
//                                            destinationURL:self.deathStarURL];
//            
//            [[self monitoringController] setDelegate:self];
//        } else {
//            //cancel
//            self.isMonitoring = NO;
//            self.startMonitoringButton.title = @"Start Monitoring";
//            
//            [[self monitoringController] stop];
//            
//            [[self monitoringController] setDelegate:nil];
//        }
//    }
//}

- (bool)fileTransferManagerIsValid
{
    if (self.locationNameTextField.stringValue.length == 0) {
        return NO;
    }
    
    if (self.routineTextField.stringValue.length == 0) {
        return NO;
    }
    
    if (!self.deathStarURL || self.deathStarLocationLabel.stringValue.length == 0) {
        return NO;
    }
    
    if (!self.scratchURL || self.scratchDiskLocationLabel.stringValue.length == 0) {
        return NO;
    }
    
    if (!self.compressionURL || self.compressionLocationLabel.stringValue.length == 0) {
        return NO;
    }
    
    if ([self shouldEnableRoutineSubFolderButton]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)isCompressedSelected
{
    if (self.qualityTypeSelector.indexOfSelectedItem == 1 || self.qualityTypeSelector.indexOfSelectedItem == 2) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isHighQualitySelected
{
    if (self.qualityTypeSelector.indexOfSelectedItem == 0 || self.qualityTypeSelector.indexOfSelectedItem == 2) {
        return YES;
    }
    
    return NO;
}

- (void)startMonitoring
{
    if ([self fileTransferManagerIsValid]) {
        [self.monitoringIndicator setHidden:NO];
        self.transferStatusLabel.stringValue = @"Ready to copy files...";
        
        [[self monitoringController] runWithWatchedURL:self.scratchURL
                             highQualityDestinationURL:self.deathStarURL
                              compressedDestinationURL:self.compressionURL
                                shouldSendCompressed:[self isCompressedSelected]
                                 shouldSendFullQuality:[self isHighQualitySelected]];
        
        [[self monitoringController] setDelegate:self];
        
        [self.monitoringIndicator startAnimation:self];
        
        self.isMonitoring = YES;
    } else {
        self.transferStatusLabel.stringValue = @"Not ready to copy files...";
        [self.monitoringIndicator setHidden:YES];
        
        self.isMonitoring = NO;
    }
}

- (void)stopMonitoring
{
    self.isMonitoring = NO;
    
    self.transferStatusLabel.stringValue = @"Not ready to copy files...";

    [self.monitoringIndicator setHidden:YES];
    
    [[self monitoringController] stop];
    
    [[self monitoringController] setDelegate:nil];
}

- (void)queueOperationDidFinished:(FileCopyOperation *)fileCopyOperation
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self updateMonitoringStatusState:[NSString stringWithFormat:@"Ready to copy files..."]];
    });
}

- (void)queueOperationStatusUpdate:(FileCopyOperation *)fileCopyOperation
{
    [self updateMonitoringStatusState:[NSString stringWithFormat:@"Copying %@", fileCopyOperation.fName]];
}

- (void)queueOperationWillStart:(FileCopyOperation *)fileCopyOperation
{
    [self updateMonitoringStatusState:[NSString stringWithFormat:@"Copying %@", fileCopyOperation.fName]];
}

- (void)updateMonitoringStatusState:(NSString *)statusString
{
    self.transferStatusLabel.stringValue = statusString;
}

- (VPMonitoringController *)monitoringController
{
    if (!_monitoringController) {
        _monitoringController = [[VPMonitoringController alloc] init];
    }
    
    return _monitoringController;
}


@end
