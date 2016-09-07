//
//  NSImage+saveAsJpegWithName.m
//  Death Star Communicator
//
//  Created by Ryan Phillip Thomas on 9/1/16.
//  Copyright © 2016 Ryan Phillip Thomas. All rights reserved.
//

#import "NSImage+saveAsJpegWithName.h"

@implementation NSImage (saveAsJpegWithName)

- (void)saveAsJpegWithName:(NSString*)fileName
{
    // Cache the reduced image
    NSData *imageData = [self TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
    [imageData writeToFile:fileName atomically:NO];
}

@end
