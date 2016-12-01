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
#import <Foundation/NSStream.h>
#import "ReceivingFileServer.h"

@class MHWDirectoryWatcher;

@interface SendingViewController :  NSViewController <NSStreamDelegate> {
    //NSInputStream	*inputStream;
    NSOutputStream	*outputStream;
    NSData *imageData;
    NSMutableArray *imageArray;
    NSUInteger byteIndex;
    ReceivingFileServer * mReceiveServer;
    

    //IBOutlet IKImageView *  mImageView;
    IBOutlet NSWindow *     mWindow;
    IBOutlet NSTextField	*mResult;
    IBOutlet NSTextField	*mFileName;
    NSDictionary * mImageProperties;
    NSString * mImageUTType;
    NSString * path ;
    BOOL isHeader;
    
    NSInteger fileCount;
    NSFileManager * fileManager;
}
- (void) initNetworkCommunication;
- (void) openImageURL: (NSURL*)url;
- (void) processImageList;

- (IBAction) sendAndroid : (id)sender;
- (IBAction) openImage: (id)sender;

@property (nonatomic, strong) MHWDirectoryWatcher *directoryWatcher;

@end
