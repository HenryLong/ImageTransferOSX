//
//  SendingViewController.h
//  ImageTransfer
//
//  Created by LongHenry on 2016/3/15.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <AppKit/AppKit.h>
#import "MHWDirectoryWatcher.h"
#include "ReceivingFileServer.h"
#include "SendingFileClient.h"

@class MHWDirectoryWatcher;

@interface SendingViewController :  NSViewController <NSDraggingDestination> {
    NSData *imageData;
    NSMutableArray *imageArray;
    ReceivingFileServer *mReceiveServer;
    SendingFileClient *mSendingClient;
    
    IBOutlet IKImageView    *mImageView;
    IBOutlet NSWindow       *mWindow;
    IBOutlet NSTextField	*mResult;
    IBOutlet NSTextField	*mFileName;
    NSDictionary *mImageProperties;
    NSString *mImageUTType;
    NSString *path;
    NSInteger fileCount;
    NSFileManager *fileManager;
}

- (void) openImageURL: (NSURL*)url;
- (NSUInteger) processImageList;

- (IBAction) sendAndroid : (id)sender;
- (IBAction) openImage: (id)sender;


//we need export below variable
@property IBOutlet NSTextField	*mResult;
@property IBOutlet NSTextField	*mFileName;
@property IBOutlet NSWindow *mWindow;
@property NSString *path ;
@property NSData *imageData;


@property (nonatomic, strong) MHWDirectoryWatcher *directoryWatcher;

@end
