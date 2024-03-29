/*
 Copyright 2015 Luis A. Rodríguez-Rivera
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <Cocoa/Cocoa.h>
#import "FileCopyOperation.h"

@class FileCopyManager;

// Delegate declaration
@protocol QueueOperationDelegate;

/**
 * Main queue controller for adding, removing or cancelling FileCopyOperations.
 */
@interface QueueWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, FileCopyOperationDelegate>

@property (nonatomic, strong) id<QueueOperationDelegate> delegate; ///< FileCopyOperationDelegate.
@property (nonatomic) NSMutableArray * fileCopyOperations; ///< Holds all FileCopyOperations objects for progress tracking and cleaning up purposes.
//@property (nonatomic, weak) id<QueueWindowOperationDelegate> delegate; ///< FileCopyOperationDelegate.

/**
 * Creates a FileCopyOperation object with the parameters given and
 * adds the operation to the FileCopyManager's FileCopyQueue.
 * @param source The source URL.
 * @param destination The destination URL.
 * @see FileCopyManager
 * @see FileCopyOperation
 * @return void
 */
- (void)addFileCopyOperationWithSource:(NSURL*)source andDestination:(NSURL*)destination;

/**
 * Cancels all queued and executing operations currently on the FileCopyManager's FileCopyQueue.
 * @see FileCopyManager
 */
- (void)cancelAllOperations;

/**
 * Removes the FileCopyOperation represented object from the table view and the fileCopyOperations array.
 * @param object The object to be removed.
 */
- (void)removeObject:(id)object;

- (void)lazyLoad;

@end;

/** Delegate implementation */
@protocol QueueOperationDelegate <NSObject>
@optional
/**
 * This delegate method gets called when the FileCopyOperation is about to start.
 * Any GUI prep code goes here.
 * @param fileCopyOperation The FileCopyOperation object.
 */
- (void)queueOperationWillStart:(FileCopyOperation*)fileCopyOperation;

/**
 * This delegate method gets called when the FileCopyOperation finishes.
 * Any cleanup code goes here.
 * @param fileCopyOperation The FileCopyOperation object.
 */
- (void)queueOperationDidFinished:(FileCopyOperation*)fileCopyOperation;

/**
 * This delegate method gets called when FileCopyOperation writes data.
 * Is used to update file copy progress.
 * @param fileCopyOperation The FileCopyOperation object.
 */
- (void)queueOperationStatusUpdate:(FileCopyOperation*)fileCopyOperation;
@end
