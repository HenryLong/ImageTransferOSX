//
//  RecevingFileServer.h
//  ImageTransfer
//
//  Created by LongHenry on 2016/11/18.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface ReceivingFileServer : NSObject <NSStreamDelegate> {
    __weak NSWindow *mWindow;
    NSMutableData *data;
    NSString *fileName;
    BOOL isHeader;
}

@property (nonatomic, weak) NSWindow *mWindow;

- (int)setup;
- (void)setview : (NSWindow *)window;


@end
