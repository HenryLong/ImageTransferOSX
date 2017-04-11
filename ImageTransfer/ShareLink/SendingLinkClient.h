//
//  SendLinkClient.h
//  ImageTransfer
//
//  Created by HenryLong on 2017/4/11.
//  Copyright © 2017年 qisda. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <Foundation/NSStream.h>
#import "../Command.h"

@class SendingShareLinkController;

@interface SendingLinkClient : NSObject <NSStreamDelegate> {
    SendingShareLinkController *mViewController;
    NSUInteger byteIndex;
    NSOutputStream *outputStream;
    BOOL isHeader;
}


- (void) initNetworkCommunication;
- (void) setLinkview : (SendingShareLinkController *)viewController;

@end

