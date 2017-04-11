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
    NSMutableArray *imageArray;
    ReceivingFileServer *mReceiveServer;
    SendingFileClient *mSendingClient;
    NSDictionary *mImageProperties;
    NSString *mImageUTType;
    NSInteger fileCount;
    NSFileManager *fileManager;
}

- (void) openImageURL: (NSURL*)url;
- (NSUInteger) processImageList;

- (IBAction) sendAndroid : (id)sender;
- (IBAction) openImage: (id)sender;
- (IBAction) showHelp: (id)sender;


//we need export below variable
@property (nonatomic, weak) IBOutlet NSTextField *mResult;
@property (nonatomic, weak) IBOutlet NSTextField *mFileName;
@property (nonatomic, weak) IBOutlet NSTextField *mUserName;
@property (nonatomic, weak) IBOutlet NSWindow *mWindow;
@property (nonatomic, weak) IBOutlet IKImageView *mImageView;
@property NSString *path ;
@property NSData *imageData;


@property (nonatomic, strong) MHWDirectoryWatcher *directoryWatcher;

@end
