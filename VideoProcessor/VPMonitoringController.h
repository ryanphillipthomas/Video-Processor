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

#import <Foundation/Foundation.h>
#import <CDEvents/CDEventsDelegate.h>

@class CDEvents;

@import AppKit;
@import AVFoundation;

@protocol VPMonitoringDelegate <NSObject>
- (void)didUpdateFolderStructure;
- (void)didAddFileToQueSourceURL:(NSURL *)sourceURL andDestination:(NSURL *)destinationURL;
- (void)didUpdateCompressionValue:(NSNumber *)value;
@end


@interface VPMonitoringController : NSObject <CDEventsDelegate , NSUserNotificationCenterDelegate> {
	CDEvents				*_events;
}

@property (weak, nonatomic) id<VPMonitoringDelegate> delegate;
@property (nonatomic, strong) NSTimer *exportProgressBarTimer;
@property (nonatomic, strong) NSNumber *exportProgressBarValue;
@property (nonatomic, strong) AVAssetExportSession *exportSession;



- (void)runWithWatchedURL:(NSURL *)watchedURL
highQualityDestinationURL:(NSURL *)highQualityDestinationURL
 compressedDestinationURL:(NSURL *)compressedDestinationURL;

- (void)stop;

@end
