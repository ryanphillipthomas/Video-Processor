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

@import AppKit;
@import AVFoundation;

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
           destinationURL:(NSURL *)destinationURL
{
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    NSArray *watchedURLs = [NSArray arrayWithObject:watchedURL];

    CDEventsEventStreamCreationFlags creationFlags = kCDEventsDefaultEventStreamFlags;
    
    if (systemVersionIsAtLeast(10,6)) {
        creationFlags |= kFSEventStreamCreateFlagIgnoreSelf;
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
                                                       [self startFileTransfer:event.URL
                                                                destinationURL:destinationURL
                                                                    watchedURL:watchedURL
                                                                   routineName:[[event.URL pathComponents] objectAtIndex:[[event.URL pathComponents] count] - 2]
                                                                  locationName:[[event.URL pathComponents] objectAtIndex:[[event.URL pathComponents] count] - 3]];
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
    
    NSLog(@"-[CDEventsTestAppController run]:\n%@\n------\n%@",
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


- (void)startFileTransfer:(NSURL *)sourceURL
           destinationURL:(NSURL *)destinationURL
               watchedURL:(NSURL *)watchedURL
              routineName:(NSString *)routineName
             locationName:(NSString *)locationName
{
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
                
                //detect quality settings and change??
                [self.delegate didAddFileToQueSourceURL:blockSourceURL andDestination:blockDestinationURL];
                
//                [self getImageAtURL:blockSourceURL andSaveToSourceURL:blockDestinationURL];
                [self getVideoAtURL:blockSourceURL andSaveToSourceURL:blockDestinationURL];
            }];
        }
    }];
}

- (void)getImageAtURL:(NSURL *)url andSaveToSourceURL:(NSURL *)sourceURL
{
    //todo dynamically detect image size and do a scaled reduction...
    NSSize testSize = NSMakeSize (200, 200);
    NSImage *sourceImage = [[NSImage alloc] initByReferencingURL:url];
    NSImage *resizedImage = [self imageResize:sourceImage newSize:testSize];
    [resizedImage saveAsJpegWithName:sourceURL.path];
}

-(void)getVideoAtURL:(NSURL *)url andSaveToSourceURL:(NSURL *)sourceURL
{
    //todo save as orginal name just with additional options...
    NSURL *blockDestinationURL = [sourceURL URLByAppendingPathComponent:@"/test.mov"];
    [self convertVideoToLowQuailtyWithInputURL:url outputURL:blockDestinationURL handler:^(AVAssetExportSession *session) {
        //do nothing
    }];
}

- (void)convertVideoToLowQuailtyWithInputURL:(NSURL*)inputURL
                                   outputURL:(NSURL*)outputURL
                                     handler:(void (^)(AVAssetExportSession*))handler
{
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPreset640x480];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void)
     {
         handler(exportSession);
     }];
}


- (NSImage *)imageResize:(NSImage*)anImage newSize:(NSSize)newSize {
    NSImage *sourceImage = anImage;
   // [sourceImage setScalesWhenResized:YES];
    
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
