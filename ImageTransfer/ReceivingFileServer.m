//
//  RecevingFileServer.m
//  ImageTransfer
//
//  Created by LongHenry on 2016/11/18.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import "ReceivingFileServer.h"
#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
/* Port to listen on */
#define PORT 8989


NSWindow *mWindow;
CFReadStreamRef readStream;
NSMutableData *data;
NSString *fileName;
BOOL isHeader;

@implementation ReceivingFileServer

- (void)setview : (NSWindow *)window{
    mWindow = window;
}

- (int)setup {
     /* The server socket */
     CFSocketRef TCPServer;
    
     /* Used by setsockopt */
     int yes = 1;
     
     /* Build our socket context; */
     CFSocketContext CTX = { 0, NULL, NULL, NULL, NULL };
     
     /* Create the server socket as a TCP IPv4 socket and set a callback */
     /* for calls to the socket's lower-level accept() function */
     TCPServer = CFSocketCreate(NULL, PF_INET, SOCK_STREAM, IPPROTO_TCP,
                                kCFSocketAcceptCallBack, (CFSocketCallBack)acceptCallBack, &CTX);
     if (TCPServer == NULL)
         return EXIT_FAILURE;
     
     /* Re-use local addresses, if they're still in TIME_WAIT */
     setsockopt(CFSocketGetNative(TCPServer), SOL_SOCKET, SO_REUSEADDR,
                (void *)&yes, sizeof(yes));
     
     /* Set the port and address we want to listen on */
     struct sockaddr_in addr;
     memset(&addr, 0, sizeof(addr));
     addr.sin_len = sizeof(addr);
     addr.sin_family = AF_INET;
     addr.sin_port = htons(PORT);
     addr.sin_addr.s_addr = htonl(INADDR_ANY);
     
     NSData *address = [ NSData dataWithBytes: &addr length: sizeof(addr) ];
     if (CFSocketSetAddress(TCPServer, (CFDataRef) address) != kCFSocketSuccess) {
         NSLog(@"CFSocketSetAddress() failed\n");
         CFRelease(TCPServer);
         return EXIT_FAILURE;
     }
     
     CFRunLoopSourceRef sourceRef = CFSocketCreateRunLoopSource(kCFAllocatorDefault, TCPServer, 0);
     CFRunLoopAddSource(CFRunLoopGetCurrent(), sourceRef, kCFRunLoopCommonModes);
     CFRelease(sourceRef);
     
     NSLog(@"Socket listening on port %d\n", PORT);
     
     CFRunLoopRun();
     return 0;
}

void acceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address,
                    const void *data,
                    void *info)
{
    NSLog(@"acceptCallBack");
    readStream = NULL;
    CFOptionFlags registeredEvents = (kCFStreamEventOpenCompleted | kCFStreamEventHasBytesAvailable |
                                      kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred);
    CFStreamClientContext ctx = {0, NULL, NULL, NULL, NULL};
    
    
    /* The native socket, used for various operations */
    CFSocketNativeHandle sock = *(CFSocketNativeHandle *) data;
    
    
    /* Create the read and write streams for the socket */
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, sock, &readStream, NULL);

    if (!readStream ) {
        close(sock);
        NSLog(@"CFStreamCreatePairWithSocket() failed\n");
        return;
    }
    
    // Schedule the stream on the run loop to enable callbacks
    if(CFReadStreamSetClient(readStream, registeredEvents, readCallback, &ctx))
    {
        CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    }
    
    if (CFReadStreamOpen(readStream) == NO) {
        NSLog(@"Failed to open read stream");
        return;
    }
    
}

void readCallback(CFReadStreamRef stream,CFStreamEventType event, void *myPtr)
{

    int kBufferSize = 1024;
    switch(event) {
        case kCFStreamEventOpenCompleted:{
            NSLog(@"Stream opened!");
            isHeader = true;
            data = [NSMutableData new];
            break;
        }
            
        case kCFStreamEventHasBytesAvailable: {
            // Read bytes until there are no more
            //
            
            while (CFReadStreamHasBytesAvailable(stream)) {
                UInt8 buffer[kBufferSize];
                long numBytesRead = CFReadStreamRead(stream, buffer, kBufferSize);
                //NSLog(@"readStream read %ld\n", numBytesRead);
                if (numBytesRead > 0) {
                    if(isHeader){
                        uint8_t headerBuf[1024];
                        uint8_t len = buffer[0];
                        for (int i = 0 ; i < len; i ++){
                            headerBuf[i] = buffer[i+1];
                        }
                        fileName = [[NSString alloc] initWithBytes:headerBuf length:len encoding:NSASCIIStringEncoding];
                        NSLog(@"fileName %@\n", fileName);
                        isHeader = false;
                        break;
                    }
                    
                    [data appendBytes:(const void *)buffer  length:numBytesRead];
                }
            }

            break;
        }
            
        case kCFStreamEventErrorOccurred: {
            CFErrorRef error = CFReadStreamCopyError(stream);
            if (error != NULL) {
                if (CFErrorGetCode(error) != 0) {
                    NSString * errorInfo = [NSString stringWithFormat:@"Failed while reading stream; error '%@' (code %ld)", (__bridge NSString*)CFErrorGetDomain(error), CFErrorGetCode(error)];
                    NSLog(@"errorInfo %@\n", errorInfo);
                    NSAlert *theAlert = [[NSAlert alloc] init];
                    [theAlert setMessageText:@"Error reading stream!"];
                    [theAlert setInformativeText:[NSString stringWithFormat:@"Error %ld: %@",
                                                  CFErrorGetCode(error), errorInfo]];
                    [theAlert addButtonWithTitle:@"OK"];
                    [theAlert beginSheetModalForWindow:mWindow completionHandler:^(NSInteger result) {
                    }];
                }
                
                CFRelease(error);
            }
            CFReadStreamClose(stream);
            break;
        }
            
        case kCFStreamEventEndEncountered:{
            // Finnish receiveing data
            //
            NSLog(@"kCFStreamEventEndEncountered");
            NSImage *image = [[NSImage alloc] initWithData:data];
            NSString *home = NSHomeDirectory();
            NSString *downloads = [NSString stringWithFormat:@"%@%@", home, @"/Downloads/"];
            NSString *path = [NSString stringWithFormat:@"%@%@", downloads, fileName];
            saveImage(image, path);

            // Clean up
            //
            CFReadStreamClose(stream);
            CFReadStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
            CFRunLoopStop(CFRunLoopGetCurrent());
            
            //popup dialog
            NSAlert *theAlert = [[NSAlert alloc] init];
            [theAlert setMessageText:@"Receivied Image"];
            [theAlert setInformativeText:[NSString stringWithFormat:@"Downloaded: %@",path]];
            [theAlert addButtonWithTitle:@"OK"];
            [theAlert beginSheetModalForWindow:mWindow completionHandler:^(NSInteger result) {
            }];
            
            break;
        }
        default:
            break;
    }
}

void saveImage(NSImage *image, NSString *path) {
    
    CGImageRef cgRef = [image CGImageForProposedRect:NULL
                                             context:nil
                                               hints:nil];
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    [newRep setSize:[image size]];   // if you want the same resolution
    NSDictionary *propImg = [ NSDictionary dictionaryWithObjectsAndKeys :
                             [ NSNumber numberWithBool : true ],
                             NSImageInterlaced, nil ];

    NSData *pngData = [newRep representationUsingType:NSPNGFileType properties:propImg];
    [pngData writeToFile:path atomically:YES];
    launchGallery(path);
}

void launchGallery(NSString *path) {
    [[NSWorkspace sharedWorkspace] openFile:path
                            withApplication:nil];
}

@end
