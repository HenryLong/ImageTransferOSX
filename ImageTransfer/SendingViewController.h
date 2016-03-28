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

@class MHWDirectoryWatcher;

@interface SendingViewController :  NSView <NSStreamDelegate> {
    NSInputStream	*inputStream;
    NSOutputStream	*outputStream;
    NSData *imageData;
    NSUInteger byteIndex;
    

    IBOutlet IKImageView *  mImageView;
    IBOutlet NSWindow *     mWindow;
    IBOutlet NSTextField	*result;
    NSDictionary * mImageProperties;
    NSString * mImageUTType;
    NSString * path ;
    
    NSInteger fileCount;
    NSFileManager * fileManager;
}
- (void) initNetworkCommunication;
- (void) openImageURL: (NSURL*)url;

- (IBAction) sendAndroid : (id)sender;
- (IBAction)openImage: (id)sender;

@property (nonatomic, strong) MHWDirectoryWatcher *directoryWatcher;

@end
