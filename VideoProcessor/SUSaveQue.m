//
//  SUSaveQue.m
//  VideoProcessor
//
//  Created by Ryan Phillip Thomas on 4/2/15.
//  Copyright © 2016 Ryan Phillip Thomas. All rights reserved.
//

#import "SUSaveQue.h"

@implementation SUSaveQue

+ (id)sharedManager
{
    static dispatch_once_t pred;
    static SUSaveQue *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[SUSaveQue alloc] init];
        
    });
    return shared;
}

- (NSOperationQueue *) saveQueue {
    if (!_saveQueue) {
        self.saveQueue = [NSOperationQueue new];
        _saveQueue.maxConcurrentOperationCount = 1;
    }
    return _saveQueue;
}

@end
