//
//  SendingViewController.m
//  ImageTransfer
//
//  Created by LongHenry on 2016/3/15.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import "SendingViewController.h"
#import <CoreFoundation/CFStream.h>
#import <Foundation/NSRunLoop.h>
#import "MHWDirectoryWatcher.h"


@implementation SendingViewController


- (void) initNetworkCommunication {
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    NSString *ip = @"192.168.49.1";
    UInt32 port = 8988;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)ip, port, &readStream, &writeStream);
    
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];
    [outputStream open];
     byteIndex =0;
    
}

- (void)awakeFromNib
{
    NSString *   _path = [[NSBundle mainBundle] pathForResource: @"Qisda" ofType: @"jpg"];   //default picture
    NSURL *      url = [NSURL fileURLWithPath: _path];
    result.stringValue=@"Result";
    
    [self openImageURL: url];
    
    // customize the IKImageView...
    [mImageView setDoubleClickOpensImageEditPanel: NO];
    [mImageView setCurrentToolMode: IKToolModeNone];
    [mImageView zoomImageToFit: self];
    
    
    NSArray *fileList = [[NSArray alloc] init];
    NSError *error = nil;
    fileManager = [NSFileManager defaultManager];
    fileList = [fileManager contentsOfDirectoryAtPath:[self pathToMonitor] error:&error];
    fileCount = [fileList count];  //update filecount
    
    self.directoryWatcher = [MHWDirectoryWatcher directoryWatcherAtPath:[self pathToMonitor] callback:^{[self directoryDidChange];}];

}

- (void)openImageURL: (NSURL*)url
{
    [mImageView setImageWithURL: url];
    [mWindow setTitleWithRepresentedFilename: [url path]];
    
    path = [url path];  //keep the path to transfer
    imageData = [[NSFileManager defaultManager] contentsAtPath:path];  //construct imgaeData
}


- (IBAction)openImage: (id)sender   //user open a new file from titlebar
{
    NSOpenPanel * openPanel = [NSOpenPanel openPanel];
    NSString *    extensions = @"tiff/tif/TIFF/TIF/jpg/jpeg/JPG/JPEG/png/PNG";
    NSArray *     types = [extensions pathComponents];
    
    [openPanel beginSheetForDirectory: NULL
                                 file: NULL
                                types: types
                       modalForWindow: mWindow
                        modalDelegate: self
                       didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
                          contextInfo: NULL];
    
}

- (void)openPanelDidEnd: (NSOpenPanel *)panel
             returnCode: (int)returnCode
            contextInfo: (void  *)contextInfo
{
    if (returnCode == NSModalResponseOK)
    {
        [self openImageURL: [[panel URLs] objectAtIndex: 0]];
    }
}


- (IBAction) sendAndroid : (id)sender
{
    [self initNetworkCommunication];
}


- (NSString *)pathToMonitor
{
    NSString * home = NSHomeDirectory();
    NSString * desktop = [NSString stringWithFormat:@"%@%@", home, @"/Desktop"];
    return desktop;
}

- (void)directoryDidChange
{
    //NSLog(@"Files changed at: %@", self.directoryWatcher.watchedPath);
    NSError *error = nil;
    NSArray *fileList = [[NSArray alloc] init];
    fileList = [fileManager contentsOfDirectoryAtPath:self.directoryWatcher.watchedPath error:&error];
    if (fileCount >= [fileList count]){
        fileCount = [fileList count];
        return;    //delete/modify case
    }
    fileCount = [fileList count];  //update new filecount
    // sort by creation date
    NSMutableArray* filesAndProperties = [NSMutableArray arrayWithCapacity:[fileList count]];
    for(NSString* file in fileList) {
        NSString* filePath = [self.directoryWatcher.watchedPath stringByAppendingPathComponent:file];
        NSDictionary* properties = [fileManager attributesOfItemAtPath:filePath error:&error];
        NSDate* modDate = [properties objectForKey:NSFileModificationDate];
        
        if(error == nil)
        {
            [filesAndProperties addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                           filePath, @"path",
                                           modDate, @"lastModDate",
                                           [filePath pathExtension], @"format",
                                           nil]];
        }
    }
    
    // sorting
    NSArray* sortedFiles = [filesAndProperties sortedArrayUsingComparator:
                            ^(id path1, id path2)
                            {
                                // compare
                                NSComparisonResult comp = [[path1 objectForKey:@"lastModDate"] compare:
                                                           [path2 objectForKey:@"lastModDate"]];
                                // invert ordering
                                if (comp == NSOrderedDescending) {
                                    comp = NSOrderedAscending;
                                }
                                else if(comp == NSOrderedAscending){
                                    comp = NSOrderedDescending;
                                }
                                return comp;
                            }];
    
    NSString * transfer_path = [[sortedFiles objectAtIndex:0] objectForKey:@"path"];
    NSString * format = [[sortedFiles objectAtIndex:0] objectForKey:@"format"];
    if( [format isEqualToString:@"png"]){
        //send to remote socket
        NSLog(@"File to send: %@", transfer_path);
        imageData = [[NSFileManager defaultManager] contentsAtPath:transfer_path];  //construct imgaeFata
        [self initNetworkCommunication];
    }
}




- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    
    //NSLog(@"stream event %i", streamEvent);
    
    switch (streamEvent) {
            
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened!");
            result.stringValue = @"Stream opened!";
            break;
        case NSStreamEventHasBytesAvailable:
            
            if (theStream == inputStream) {  //response from server , but not be used in the prj now
                uint8_t buffer[1024];
                NSUInteger len;
                
                while ([inputStream hasBytesAvailable]) {
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output) {
                            NSLog(@"server said: %@", output);
                            result.stringValue = output;
                            
                        }
                    }
                }
            }
            break;
            
            
        case NSStreamEventErrorOccurred:
            
            NSLog(@"Can not connect to the host!");
            result.stringValue = @"Can not connect to the host!";
            break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"NSStreamEventEndEncountered!");
            result.stringValue = @"NSStreamEventEndEncountered!";
            if(theStream == outputStream){
               [inputStream close];
               [outputStream close];
            }
            
            break;
        case NSStreamEventHasSpaceAvailable:
            if (theStream == outputStream){
                NSLog(@"NSStreamEventHasSpaceAvailable!");
                result.stringValue = @"NSStreamEventHasSpaceAvailable!";
                
                uint8_t *readBytes = (uint8_t *)[imageData bytes];
                readBytes += byteIndex; // instance variable to move pointer
                NSUInteger data_len = [imageData length];
                NSUInteger len = ((data_len - byteIndex >= 1024) ?
                                    1024 : (data_len - byteIndex));
                uint8_t buf[len];
                (void)memcpy(buf, readBytes, len);
                len = [outputStream write:(const uint8_t *)buf maxLength:len];
                byteIndex += len;
                break;
            }
            
            break;
        default:
            NSLog(@"Unknown event");
            result.stringValue = @"Unknown event";
    }
    
}


@end
