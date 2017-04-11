//
//  SendingFileClient.h
//  ImageTransfer
//
//  Created by LongHenry on 2016/12/7.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <Foundation/NSStream.h>
#include "Command.h"

@class SendingViewController;

@interface SendingFileClient : NSObject <NSStreamDelegate> {
    SendingViewController *mViewController;
    NSUInteger byteIndex;
    NSOutputStream *outputStream;
    BOOL isHeader;
}


- (void) initNetworkCommunication;
- (void) setview : (SendingViewController *) viewController;

@end


