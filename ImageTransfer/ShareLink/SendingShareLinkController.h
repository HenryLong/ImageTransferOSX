//
//  SendingShareLinkController.h
//  ImageTransfer
//
//  Created by HenryLong on 2017/4/10.
//  Copyright © 2017年 qisda. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "SendingLinkClient.h"


@interface SendingShareLinkController : NSViewController{
    SendingLinkClient *mSendingLinkClient;
}

@property (nonatomic, weak) IBOutlet NSWindow *mWindow;
@property (nonatomic, weak) IBOutlet NSTextField *mUserName;
@property (nonatomic, weak) IBOutlet NSTextField *mShareLink;


- (IBAction) sendAndroid : (id)sender;
@end

