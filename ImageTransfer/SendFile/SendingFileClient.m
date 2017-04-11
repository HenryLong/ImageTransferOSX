//
//  SendingFileClient.m
//  ImageTransfer
//
//  Created by LongHenry on 2016/12/7.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SendingFileClient.h"
#import "SendingViewController.h"

NSString *description = @"";

@implementation SendingFileClient

- (void)setview : (SendingViewController *) viewController{
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
            mViewController.mResult.stringValue = @"Stream opened!";
            isHeader = true;
            break;
        }
        case NSStreamEventHasBytesAvailable:
        {
            break;
        }
        case NSStreamEventErrorOccurred:
        {
            NSLog(@"Can not connect to the host!");
            mViewController.mResult.stringValue = @"Can not connect to the host!";
            
            
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
            mViewController.mResult.stringValue = @"NSStreamEventEndEncountered!";
            if(theStream == outputStream){
                [outputStream close];
                [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                outputStream = nil; // stream is ivar, so reinit it
            }
            
            description = [NSString stringWithFormat:@"%@%@\n\n", description, mViewController.path];
            NSUInteger mCount = [mViewController processImageList]; //To process others if exist
            NSLog(@"mCount: %ld",mCount);
            
            if(mCount == 0){
                NSLog(@"Process finished");
                NSAlert *theAlert = [[NSAlert alloc] init];
                [theAlert setMessageText:@"Send Successfully"];
                [theAlert setInformativeText:[NSString stringWithFormat:@"%@",description]];
                [theAlert addButtonWithTitle:@"OK"];
                [theAlert beginSheetModalForWindow: (mViewController.mWindow) completionHandler:^(NSInteger result) {
                    NSLog(@"Sent dialog show");
                    description = @"";  //reset
                }];
            }
            
            break;
        }
        case NSStreamEventHasSpaceAvailable:
        {
            if (theStream == outputStream){
                //NSLog(@"NSStreamEventHasSpaceAvailable!");
                mViewController.mResult.stringValue = @"NSStreamEventHasSpaceAvailable!";
                
                if(isHeader){   //everytime transfer packet header first, 1024 bytes for length + filename
                    uint8_t cmd[1024];
                    NSUInteger cmdLen = 1024;
                    constructSendFileHeader(mViewController, cmd , cmdLen);

                    [outputStream write:(const uint8_t *)cmd maxLength:cmdLen];
                    NSLog(@"outputStream write header %ld\n", cmdLen);
                    isHeader = false;
                }

                uint8_t *readBytes = (uint8_t *)[mViewController.imageData bytes];
                readBytes += byteIndex; // instance variable to move pointer
                NSUInteger data_len = [mViewController.imageData length];
                NSUInteger len = ((data_len - byteIndex >= 1024) ?
                                                    1024 : (data_len - byteIndex));
                uint8_t buf[len];
                (void)memcpy(buf, readBytes, len);
                len = [outputStream write:(const uint8_t *)buf maxLength:len];
                //NSLog(@"outputStream write %ld\n", len);
                byteIndex += len;
            }
            break;
        }
        default:
            NSLog(@"Unknown event");
            mViewController.mResult.stringValue = @"Unknown event";
    }
    
}

void constructSendFileHeader(SendingViewController* mViewController, uint8_t* cmd, NSUInteger cmdLen) {
    
    NSData* userName = [[mViewController.mUserName stringValue] dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t * userNameBytes = (uint8_t *)[userName bytes];
    
    NSData* fileName = [[mViewController.mFileName stringValue] dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t * fileNameBytes = (uint8_t *)[fileName bytes]; //transfer fileName to bytes array

    //cmd Type 1 byte
    cmd[0] = TYPE_SEND_FILE;
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
    cmd[index++] = fileName.length;
    //cmd file name, Value
    for (int i = 0 ; i < fileName.length; i ++){
        cmd[index++] = fileNameBytes[i];
    }
    
    uint8_t len = index - 3;
    cmd[2] = (len & 0xFF);
    cmd[1] = ((len >> 8) & 0xFF);
    
}

@end

