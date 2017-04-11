//
//  SendingShareLinkController.m
//  ImageTransfer
//
//  Created by HenryLong on 2017/4/10.
//  Copyright © 2017年 qisda. All rights reserved.
//

#import "SendingShareLinkController.h"

@implementation SendingShareLinkController
@synthesize mUserName;
@synthesize mShareLink;


- (void)viewDidLoad{
    mUserName.stringValue = [[NSHost currentHost] localizedName];
    //Initiate SendingClent
    mSendingLinkClient = [[SendingLinkClient alloc] init];
    [mSendingLinkClient setLinkview: self];
}

- (IBAction) sendAndroid : (id)sender
{
    [mSendingLinkClient initNetworkCommunication];
}

@end
