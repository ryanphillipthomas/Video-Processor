/**
 * CDEvents
 *
 * Copyright (c) 2010-2013 Aron Cedercrantz
 * http://github.com/rastersize/CDEvents/
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */
#import "VPMonitoringController.h"

#import <CDEvents/CDEvent.h>
#import <CDEvents/CDEvents.h>
#import "SUSaveQue.h"
#import "NSImage+saveAsJpegWithName.h"

#define CD_EVENTS_TEST_APP_USE_BLOCKS_API				1

bool systemVersionIsAtLeast(SInt32 major, SInt32 minor)
{
    static SInt32 versionMajor = 0, versionMinor = 0;

    if (versionMajor == 0) {
        Gestalt(gestaltSystemVersionMajor, &versionMajor);
    }

    if (versionMinor == 0) {
        Gestalt(gestaltSystemVersionMinor, &versionMinor);
    }

    return ((versionMajor > major) ||
            ((versionMajor == major) && (versionMinor >= minor)));
}


@implementation VPMonitoringController

- (void)runWithWatchedURL:(NSURL *)watchedURL
{
    _ftp = [FTPClient clientWithHost:@"ftp.actorreplay.com"
                                             port:21
                                         username:@"video@actorreplay.com"
                                         password:@"Ryan1217!"];
    

    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    NSArray *watchedURLs = [NSArray arrayWithObject:watchedURL];
    
    CDEventsEventStreamCreationFlags creationFlags = kCDEventsDefaultEventStreamFlags;
    
    if (systemVersionIsAtLeast(10,6)) {
        //creationFlags |= kFSEventStreamCreateFlagIgnoreSelf;
    }
    
    if (systemVersionIsAtLeast(10,7)) {
        creationFlags |= kFSEventStreamCreateFlagFileEvents;
    }
    
#if CD_EVENTS_TEST_APP_USE_BLOCKS_API
    _events = [[CDEvents alloc] initWithURLs:watchedURLs
                                       block:^(CDEvents *watcher, CDEvent *event){
                                           NSLog(@"[Block] URLWatcher: %@\nEvent: %@", watcher, event);
                                           
                                           if ([[event.URL lastPathComponent] isEqualToString:@".DS_Store"]) {
                                               return;
                                           }
                                           
                                           if ([event isDir]) {
                                               [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                   [self.delegate didUpdateFolderStructure];
                                               }];
                                           }
                                           
                                           if ([event isFile]) {
                                               if ([event isCreated] || [event isModified]) {
                                                   if (![self fileIsBeingCopied:event.URL]) {
                                                       [self startUploaderFileTransfer:event.URL watchedURL:watchedURL];
                                                   }
                                               }
                                           }
                                       }
                                   onRunLoop:[NSRunLoop currentRunLoop]
                        sinceEventIdentifier:kCDEventsSinceEventNow
                        notificationLantency:CD_EVENTS_DEFAULT_NOTIFICATION_LATENCY
                     ignoreEventsFromSubDirs:CD_EVENTS_DEFAULT_IGNORE_EVENT_FROM_SUB_DIRS
                                 excludeURLs:nil
                         streamCreationFlags:creationFlags];
#else
    _events = [[CDEvents alloc] initWithURLs:watchedURLs
                                    delegate:self
                                   onRunLoop:[NSRunLoop currentRunLoop]
                        sinceEventIdentifier:kCDEventsSinceEventNow
                        notificationLantency:CD_EVENTS_DEFAULT_NOTIFICATION_LATENCY
                     ignoreEventsFromSubDirs:CD_EVENTS_DEFAULT_IGNORE_EVENT_FROM_SUB_DIRS
                                 excludeURLs:nil
                         streamCreationFlags:creationFlags];
    //[_events setIgnoreEventsFromSubDirectories:YES];
#endif
    
    NSLog(@"-[Uploader Stream Run]:\n%@\n------\n%@",
          _events,
          [_events streamDescription]);
}

- (void)uploadManualFileFromURL:(NSURL *)localFileURL compressedDestinationURL:(NSURL *)compressedDestinationURL
{
    if (![self fileIsBeingCopied:localFileURL]) {
            [self startUploaderFileTransfer:localFileURL watchedURL:compressedDestinationURL];
    }
}


- (void)runWithWatchedURL:(NSURL *)watchedURL
highQualityDestinationURL:(NSURL *)highQualityDestinationURL
 compressedDestinationURL:(NSURL *)compressedDestinationURL
     shouldSendCompressed:(BOOL)shouldSendCompressed
    shouldSendFullQuality:(BOOL)shouldSendFullQuality
{
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    NSArray *watchedURLs = [NSArray arrayWithObject:watchedURL];

    CDEventsEventStreamCreationFlags creationFlags = kCDEventsDefaultEventStreamFlags;
    
    if (systemVersionIsAtLeast(10,6)) {
        creationFlags |= kFSEventStreamCreateFlagIgnoreSelf; //consider removal
    }
    
    if (systemVersionIsAtLeast(10,7)) {
        creationFlags |= kFSEventStreamCreateFlagFileEvents;
    }
    
#if CD_EVENTS_TEST_APP_USE_BLOCKS_API
    _events = [[CDEvents alloc] initWithURLs:watchedURLs
                                       block:^(CDEvents *watcher, CDEvent *event){
                                           NSLog(@"[Block] URLWatcher: %@\nEvent: %@", watcher, event);
                                           
                                           if ([[event.URL lastPathComponent] isEqualToString:@".DS_Store"]) {
                                               return;
                                           }
                                           
                                           if ([event isDir]) {
                                               [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                   [self.delegate didUpdateFolderStructure];
                                               }];
                                           }
                                           
                                           if ([event isFile]) {
                                               if ([event isCreated] || [event isModified]) {
                                                   if (![self fileIsBeingCopied:event.URL]) {
                                                       
                                                       if (shouldSendFullQuality) {
                                                           [self startHighQualityFileTransfer:event.URL
                                                                               destinationURL:highQualityDestinationURL
                                                                                   watchedURL:watchedURL
                                                                                  routineName:[[event.URL pathComponents] objectAtIndex:[[event.URL pathComponents] count] - 2]
                                                                                 locationName:[[event.URL pathComponents] objectAtIndex:[[event.URL pathComponents] count] - 3]];
                                                       }
                                                       
                                                       if (shouldSendCompressed) {
                                                           [self startCompressedFileTransfer:event.URL
                                                                              destinationURL:compressedDestinationURL
                                                                                  watchedURL:watchedURL
                                                                                 routineName:[[event.URL pathComponents] objectAtIndex:[[event.URL pathComponents] count] - 2]
                                                                                locationName:[[event.URL pathComponents] objectAtIndex:[[event.URL pathComponents] count] - 3]];
                                                       }
                                                   }
                                               }
                                           }
                                       }
                                   onRunLoop:[NSRunLoop currentRunLoop]
                        sinceEventIdentifier:kCDEventsSinceEventNow
                        notificationLantency:CD_EVENTS_DEFAULT_NOTIFICATION_LATENCY
                     ignoreEventsFromSubDirs:CD_EVENTS_DEFAULT_IGNORE_EVENT_FROM_SUB_DIRS
                                 excludeURLs:nil
                         streamCreationFlags:creationFlags];
#else
    _events = [[CDEvents alloc] initWithURLs:watchedURLs
                                    delegate:self
                                   onRunLoop:[NSRunLoop currentRunLoop]
                        sinceEventIdentifier:kCDEventsSinceEventNow
                        notificationLantency:CD_EVENTS_DEFAULT_NOTIFICATION_LATENCY
                     ignoreEventsFromSubDirs:CD_EVENTS_DEFAULT_IGNORE_EVENT_FROM_SUB_DIRS
                                 excludeURLs:nil
                         streamCreationFlags:creationFlags];
    //[_events setIgnoreEventsFromSubDirectories:YES];
#endif
    
    NSLog(@"-[Recorder Stream Run]:\n%@\n------\n%@",
          _events,
          [_events streamDescription]);
}

- (void)dealloc
{
	[_events setDelegate:nil];
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:nil];
}

- (void)stop
{
    [_events setDelegate:nil];
    _events = nil;
}

- (bool)fileIsBeingCopied:(NSURL *)filePath
{
    bool isBeingCopied = false;
    if([[[[NSFileManager defaultManager] attributesOfItemAtPath:[filePath path] error:nil] fileCreationDate] timeIntervalSince1970] < 0)
    {
        isBeingCopied = true;
    }
    
    return isBeingCopied;
}

- (void)URLWatcher:(CDEvents *)urlWatcher eventOccurred:(CDEvent *)event
{
	NSLog(@"[Delegate] URLWatcher: %@\nEvent: %@", urlWatcher, event);
}

- (NSString *)removeEmptySpacesFromString:(NSString *)string
{
    return [string stringByReplacingOccurrencesOfString:@" " withString:@""];
}

- (void)startUploaderFileTransfer:(NSURL *)sourceURL
                       watchedURL:(NSURL *)watchedURL
{
    __block NSURL *blockSourceURL = sourceURL;

   __block NSString *cityNamePathComponent = [[[[[sourceURL path] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByReplacingOccurrencesOfString:[watchedURL path] withString:@""] lastPathComponent];
    __block NSString *firstPathComponent = [NSString stringWithFormat:@"/%@", cityNamePathComponent];
    __block NSString *secondPathComponent = [[[sourceURL path] stringByDeletingLastPathComponent] stringByReplacingOccurrencesOfString:[watchedURL path] withString:@""];
    __block NSString *thirdPathComponent = [[sourceURL path] stringByReplacingOccurrencesOfString:[watchedURL path] withString:@""];
    
    if ([[NSFileManager defaultManager] isReadableFileAtPath:[blockSourceURL path]] ) {
        [[[SUSaveQue sharedManager] uploadQueue] addOperationWithBlock:^{
            
            BOOL firstPath = [_ftp createDirectoryAtPath:[self removeEmptySpacesFromString:firstPathComponent]];
            if (! firstPath) {
                // Display error...
            }
        
            BOOL secondPath = [_ftp createDirectoryAtPath:[self removeEmptySpacesFromString:secondPathComponent]];
            if (! secondPath) {
                // Display error...
            }
            
            if ([_ftp fileSizeAtPath:[self removeEmptySpacesFromString:thirdPathComponent]] == -1) {
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.delegate didStartUploading:[blockSourceURL lastPathComponent]];
                }];
                
                ++ _uploadCounter;
                
                [_ftp uploadFile:[blockSourceURL path] to:[self removeEmptySpacesFromString:thirdPathComponent]
                        progress:NULL
                         success:^{
                             -- _uploadCounter;
                             if (_uploadCounter == 0) {
                                 [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                     [self.delegate didFinishUploading];
                                 }];
                             }
                             
                         } failure:^(NSError *error) {
                             -- _uploadCounter;
                             
                             if (_uploadCounter == 0) {
                                 [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                     [self.delegate didFinishUploading];
                                 }];
                             }
                             
                         }];
            }
            
        }];
    }
}




- (void)startHighQualityFileTransfer:(NSURL *)sourceURL
                      destinationURL:(NSURL *)destinationURL
                          watchedURL:(NSURL *)watchedURL
                         routineName:(NSString *)routineName
                        locationName:(NSString *)locationName
{
    //The following performs the high quality video file transfers...
    __block NSURL *blockDestinationURL = destinationURL;
    __block NSURL *blockSourceURL = sourceURL;
    __block NSString *blockRoutineName = routineName;
    __block NSString *blockLocationName = locationName;

    [[[SUSaveQue sharedManager] saveQueue] addOperationWithBlock:^{
        if ([[NSFileManager defaultManager] isReadableFileAtPath:[blockSourceURL path]] ) {
            
            NSString *folderName = blockRoutineName;
            
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
                [self.delegate didAddFileToQueSourceURL:blockSourceURL andDestination:blockDestinationURL];
            }];
        }
    }];
}

- (void)startCompressedFileTransfer:(NSURL *)sourceURL
                     destinationURL:(NSURL *)destinationURL
                         watchedURL:(NSURL *)watchedURL
                        routineName:(NSString *)routineName
                       locationName:(NSString *)locationName
{
    //The following performs the compressed quality video file transfers...
    
    __block NSURL *blockDestinationURL = destinationURL;
    __block NSURL *blockSourceURL = sourceURL;
    __block NSString *blockRoutineName = routineName;
    __block NSString *blockLocationName = locationName;
    
    [[[SUSaveQue sharedManager] saveQueue] addOperationWithBlock:^{
        if ([[NSFileManager defaultManager] isReadableFileAtPath:[blockSourceURL path]] ) {
            
            NSString *folderName = blockRoutineName;
            
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
            
            if ([self isPhotoType:blockSourceURL]) {
                [self getImageAtURL:blockSourceURL andSaveToSourceURL:blockDestinationURL];
            }
            
            if ([self isVideoType:blockSourceURL]) {
                [self getVideoAtURL:blockSourceURL andSaveToSourceURL:blockDestinationURL];
            }
        }
    }];
}

- (bool)isPhotoType:(NSURL *)sourceURL
{
    NSString *url = [sourceURL path];
    if ([url containsString:@"Photo"]) {
        return YES;
    }
    
    return NO;
}

- (bool)isVideoType:(NSURL *)sourceURL
{
    NSString *url = [sourceURL path];
    if ([url containsString:@"Video"]) {
        return YES;
    }
    
    return NO;
}

- (void)getImageAtURL:(NSURL *)url andSaveToSourceURL:(NSURL *)sourceURL
{
    NSArray *parts = [url pathComponents];
    NSString *filename = [parts lastObject];
    NSString *finalFileName = [NSString stringWithFormat:@"lq_%@", filename];
    NSURL *blockDestinationURL = [[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:finalFileName];

    //todo dynamically detect image size and do a scaled reduction...
    
    NSImage *sourceImage = [[NSImage alloc] initByReferencingURL:url];
    
    CIImage *_imageCIImage = [CIImage imageWithContentsOfURL:url];
    NSRect _rectFromCIImage = [_imageCIImage extent];
    
    NSSize halfSize = NSMakeSize (_rectFromCIImage.size.width / 2, _rectFromCIImage.size.height / 2);
    [self.delegate didUpdateCompressionValue:@0];
    NSImage *resizedImage = [self imageResize:sourceImage newSize:halfSize];
    [resizedImage saveAsJpegWithName:blockDestinationURL.path];
    [self.delegate didUpdateCompressionValue:@1];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.delegate didAddFileToQueSourceURL:blockDestinationURL andDestination:sourceURL];
    }];
}

-(void)getVideoAtURL:(NSURL *)url andSaveToSourceURL:(NSURL *)sourceURL
{
    //todo save as orginal name just with additional options...
    
    NSArray *parts = [url pathComponents];
    NSString *filename = [parts lastObject];
    NSString *finalFileName = [NSString stringWithFormat:@"lq_%@", filename];
    
    NSURL *blockDestinationURL = [[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:finalFileName];
    [self convertVideoToLowQuailtyWithInputURL:url outputURL:blockDestinationURL handler:^(AVAssetExportSession *session) {
        
        //iniate file copy transfer to compressed location....
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.delegate didAddFileToQueSourceURL:blockDestinationURL andDestination:sourceURL];
        }];
    }];
}

- (void)convertVideoToLowQuailtyWithInputURL:(NSURL*)inputURL
                                   outputURL:(NSURL*)outputURL
                                     handler:(void (^)(AVAssetExportSession*))handler
{
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    self.exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPreset640x480];
    self.exportSession.outputURL = outputURL;
    self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    
    [self.delegate didUpdateCompressionValue:@0];
    [self.exportSession exportAsynchronouslyWithCompletionHandler:^(void)
     {
         [self.delegate didUpdateCompressionValue:@1];
         handler(self.exportSession);
     }];
}

- (NSImage *)imageResize:(NSImage*)anImage newSize:(NSSize)newSize {
    NSImage *sourceImage = anImage;
    // Report an error if the source isn't a valid image
    if (![sourceImage isValid]){
        NSLog(@"Invalid Image");
    } else {
        NSImage *smallImage = [[NSImage alloc] initWithSize: newSize];
        [smallImage lockFocus];
        [sourceImage setSize: newSize];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, newSize.width, newSize.height) operation:NSCompositeCopy fraction:1.0];
        [smallImage unlockFocus];
        return smallImage;
    }
    return nil;
}


@end
