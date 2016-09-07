//
//  SUSaveQue.h
//  VideoProcessor
//
//  Created by Ryan Phillip Thomas on 4/2/15.
//  Copyright © 2016 Ryan Phillip Thomas. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SUSaveQue : NSObject

+ (id)sharedManager;

/// Used to serialize Core Data operations.
@property (nonatomic) NSOperationQueue *saveQueue;

@end
