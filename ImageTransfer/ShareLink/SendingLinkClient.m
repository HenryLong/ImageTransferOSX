//
//  SendLinkClient.m
//  ImageTransfer
//
//  Created by HenryLong on 2017/4/11.
//  Copyright © 2017年 qisda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SendingLinkClient.h"
#import "SendingShareLinkController.h"


@implementation SendingLinkClient

- (void)setLinkview : (SendingShareLinkController *) viewController{
    mViewController = viewController;
}


-(void) initNetworkCommunication {
    CFWriteStreamRef writeStream;
    NSString *ip = @"192.168.49.1";
    UInt32 sendPort = 8988;
    
    byteIndex = 0;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)ip, sendPort, NULL , &writeStream);
    
    outputStream = (__bridge NSOutputStream *)writeStream;
    [outputStream setDelegate:self];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream open];
}


- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    //NSLog(@"stream event %i", streamEvent);
    switch (streamEvent) {
        case NSStreamEventOpenCompleted:
        {
            NSLog(@"Stream opened!");
            isHeader = true;
            break;
        }
        case NSStreamEventHasBytesAvailable:
        {
            NSLog(@"NSStreamEventHasBytesAvailable!");
            break;
        }
        case NSStreamEventErrorOccurred:
        {
            NSLog(@"Can not connect to the host!");
            NSError *theError = [theStream streamError];
            NSAlert *theAlert = [[NSAlert alloc] init];
            [theAlert setMessageText:@"Error sending stream!"];
            [theAlert setInformativeText:[NSString stringWithFormat:@"Error %ld: %@",
                                          [theError code], [theError localizedDescription]]];
            [theAlert addButtonWithTitle:@"OK"];
            [theAlert beginSheetModalForWindow: (mViewController.mWindow) completionHandler:^(NSInteger result) {
                NSLog(@"Alert Dialog Show");
            }];
         
            [theStream close];
            break;
        }
        case NSStreamEventEndEncountered:
        {
            NSLog(@"NSStreamEventEndEncountered!");
            //mViewController.mResult.stringValue = @"NSStreamEventEndEncountered!";
            if(theStream == outputStream){
                [outputStream close];
                [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                outputStream = nil; // stream is ivar, so reinit it
            }
            
            NSLog(@"Process finished");
            NSAlert *theAlert = [[NSAlert alloc] init];
            [theAlert setMessageText:@"Send Successfully"];
            [theAlert setInformativeText: [mViewController.mShareLink stringValue]];
            [theAlert addButtonWithTitle:@"OK"];
            [theAlert beginSheetModalForWindow: (mViewController.mWindow) completionHandler:^(NSInteger result) {
                NSLog(@"Sent dialog show");
            }];

            
            break;
        }
        case NSStreamEventHasSpaceAvailable:
        {
            if (theStream == outputStream){
                NSLog(@"NSStreamEventHasSpaceAvailable!");
                //mViewController.mResult.stringValue = @"NSStreamEventHasSpaceAvailable!";
                
                if(isHeader){ 
                    uint8_t cmd[1024];
                    NSUInteger cmdLen = 1024;
                    constructShareLinkHeader(mViewController, cmd , cmdLen);
                    
                    [outputStream write:(const uint8_t *)cmd maxLength:cmdLen];
                    NSLog(@"outputStream write header %ld\n", cmdLen);
                    isHeader = false;
                }
                //only need transfer header
                if(theStream == outputStream){
                    [outputStream close];
                    [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                    outputStream = nil; // stream is ivar, so reinit it
                }
                
            }
            break;
        }
        default:
            NSLog(@"Unknown event");
            //mViewController.mResult.stringValue = @"Unknown event";
    }
    
}

void constructShareLinkHeader(SendingShareLinkController* mViewController, uint8_t* cmd, NSUInteger cmdLen) {
    
    NSData* userName = [[mViewController.mUserName stringValue] dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t * userNameBytes = (uint8_t *)[userName bytes];
    
    NSData* shareLink = [[mViewController.mShareLink stringValue] dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t * shareLinkBytes = (uint8_t *)[shareLink bytes]; //transfer fileName to bytes array
    
    NSLog(@"userName: %@",[mViewController.mUserName stringValue]);
    NSLog(@"shareLink: %@",[mViewController.mShareLink stringValue]);
    //cmd Type 1 byte
    cmd[0] = TYPE_SHARE_LINK;
    //cmd length 2 byte
    //cmd[1],cmd[2] will fill in at last.
    //payload begin at index 3
    uint8_t index = 3;
    //cmd user name, Tag
    cmd[index++]= TAG_USER;
    //cmd user name, Len
    cmd[index++]= userName.length;
    //cmd user name, Value
    for (int i = 0 ; i < userName.length; i++){
        cmd[index++] = userNameBytes[i];
    }
    
    //cmd file name, Tag
    cmd[index++] = TAG_FILE_NAME;
    //cmd file name, Len
    cmd[index++] = shareLink.length;
    //cmd file name, Value
    for (int i = 0 ; i < shareLink.length; i ++){
        cmd[index++] = shareLinkBytes[i];
    }
    
    uint8_t len = index - 3;
    cmd[2] = (len & 0xFF);
    cmd[1] = ((len >> 8) & 0xFF);
    
}

@end
