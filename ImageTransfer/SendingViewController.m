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


@interface SendingViewController ()
@property (nonatomic, weak) IBOutlet IKImageView *  mImageView;
@end

@implementation SendingViewController


- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    //NSLog(@"stream event %i", streamEvent);
    switch (streamEvent) {
        case NSStreamEventOpenCompleted:
        {
            NSLog(@"Stream opened!");
            mResult.stringValue = @"Stream opened!";
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
            mResult.stringValue = @"Can not connect to the host!";
            NSError *theError = [theStream streamError];
            NSAlert *theAlert = [[NSAlert alloc] init];
            [theAlert setMessageText:@"Error reading stream!"];
            [theAlert setInformativeText:[NSString stringWithFormat:@"Error %ld: %@",
                                          [theError code], [theError localizedDescription]]];
            [theAlert addButtonWithTitle:@"OK"];
            [theAlert beginSheetModalForWindow:[self.view window] completionHandler:^(NSInteger result) {
                NSLog(@"Alert Dialog Show");
            }];
            [theStream close];
            break;
        }
        case NSStreamEventEndEncountered:
        {
            NSLog(@"NSStreamEventEndEncountered!");
            mResult.stringValue = @"NSStreamEventEndEncountered!";
            if(theStream == outputStream){
                //[inputStream close];
                [outputStream close];
                [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                outputStream = nil; // stream is ivar, so reinit it
            }
            NSAlert *theAlert = [[NSAlert alloc] init];
            [theAlert setMessageText:@"Send Successfully"];
            [theAlert setInformativeText:[NSString stringWithFormat:@"Sent: %@",path]];
            [theAlert addButtonWithTitle:@"OK"];
            [theAlert beginSheetModalForWindow:[self.view window] completionHandler:^(NSInteger result) {
                NSLog(@"Sent dialog show");
            }];
            isHeader = true;
            [self processImageList]; //To process others if exist
            NSLog(@"break");
            break;
        }
        case NSStreamEventHasSpaceAvailable:
        {
            if (theStream == outputStream){
                //NSLog(@"NSStreamEventHasSpaceAvailable!");
                mResult.stringValue = @"NSStreamEventHasSpaceAvailable!";
                
                if(isHeader){   //everytime transfer packet header first, 1024 bytes for length + filename
                    uint8_t headerBuf[1024];
                    NSUInteger headerLen = 1024;
                    NSData* filename = [[mFileName stringValue] dataUsingEncoding:NSUTF8StringEncoding];
                    uint8_t * filebytes = (uint8_t *)[filename bytes];
                    headerBuf[0] = filename.length;
                    for (int i = 0 ; i < filename.length; i ++){
                        headerBuf[i+1] = filebytes[i];
                    }
                    [outputStream write:(const uint8_t *)headerBuf maxLength:headerLen];
                    NSLog(@"outputStream write header %ld\n", headerLen);
                    isHeader = false;
                }
                
                uint8_t *readBytes = (uint8_t *)[imageData bytes];
                readBytes += byteIndex; // instance variable to move pointer
                NSUInteger data_len = [imageData length];
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
            mResult.stringValue = @"Unknown event";
    }
    
}


- (void) initNetworkCommunication {
    
    //CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    NSString *ip = @"192.168.49.1";
    UInt32 sendPort = 8988;

    byteIndex = 0;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)ip, sendPort, NULL , &writeStream);
    
    outputStream = (__bridge NSOutputStream *)writeStream;
    [outputStream setDelegate:self];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream open];
    
    
    //UInt32 receivePort = 8989;
    //CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)ip, receivePort, &readStream, NULL);
    //inputStream = (__bridge NSInputStream *)readStream;
    //[inputStream setDelegate:self];
    //[inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    //[inputStream open];
}




- (void)openImageURL: (NSURL*)url
{
    NSLog(@"NSURL: %@",url);
    //[mImageView setImageWithURL: url];
    [self imageDrawing : url];
    
    // customize the IKImageView...
    [self.mImageView setDoubleClickOpensImageEditPanel: NO];
    [self.mImageView setCurrentToolMode: IKToolModeNone];
    [self.mImageView zoomImageToFit: self];
    /*
    [self performSelectorOnMainThread:@selector(myCustomDrawing:)
                           withObject:url
                        waitUntilDone:YES];
    */
    path = [url path];  //keep the path to transfer
    imageData = [[NSFileManager defaultManager] contentsAtPath:path];  //construct imgaeData
    mFileName.stringValue = [path lastPathComponent];
}


- (void) imageDrawing: (NSURL*)url{
    CGImageRef          image = NULL;
    CGImageSourceRef    isr = CGImageSourceCreateWithURL( (CFURLRef)url, NULL);
    
    if (isr)
    {
        image = CGImageSourceCreateImageAtIndex(isr, 0, NULL);
        if (image)
        {
            mImageProperties =
            (NSDictionary*)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(isr, 0, (CFDictionaryRef)mImageProperties));
        }
        CFRelease(isr);
    }
    
    if (image)
    {
        [self.mImageView setImage: image
             imageProperties: mImageProperties];
        
        //[mWindow setTitleWithRepresentedFilename: [url path]];
        CGImageRelease(image);
    }
    
}

- (void)processImageList{
    NSLog(@"imageArray count: %ld", imageArray.count);
    if(imageArray.count != 0){
        NSURL *imageURL = [NSURL fileURLWithPath: [imageArray objectAtIndex:0]]; //deliver first index
        [self openImageURL: imageURL];
        NSLog(@"Sending Image");
        [self initNetworkCommunication];
        [imageArray removeObjectAtIndex:0];
    }
}


- (NSString *)pathToMonitor
{
    NSString * home = NSHomeDirectory();
    NSString * desktop = [NSString stringWithFormat:@"%@%@", home, @"/Desktop"];
    return desktop;
}

/*
 * To monitor desktop screen shot captured
 */
- (void)directoryDidChange
{
    //NSLog(@"Files changed at: %@", self.directoryWatcher.watchedPath);
    NSString* filePath;
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
        filePath = [self.directoryWatcher.watchedPath stringByAppendingPathComponent:file];
        NSDictionary* properties = [fileManager attributesOfItemAtPath:filePath error:&error];
        NSDate* modDate = [properties objectForKey:NSFileModificationDate];
        
        if(error == nil && [[filePath pathExtension]  isEqualToString: @"png"])  //only sort png file
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
    //NSString * format = [[sortedFiles objectAtIndex:0] objectForKey:@"format"];
    //send to remote socket
    NSLog(@"File to send: %@", transfer_path);
    NSURL * url = [NSURL fileURLWithPath: transfer_path];
    [self openImageURL: url];
    mFileName.stringValue = [transfer_path lastPathComponent];
    imageData = [[NSFileManager defaultManager] contentsAtPath:transfer_path];  //construct imageData
    [self initNetworkCommunication];
}


- (IBAction)openImage: (id)sender   //user open a new file from menubar
{
    NSOpenPanel * openPanel = [NSOpenPanel openPanel];
    NSString *    extensions = @"jpg/jpeg/JPG/JPEG/png/PNG";
    NSArray *     types = [extensions pathComponents];
    
    [openPanel setAllowedFileTypes: types];
    [openPanel beginSheetModalForWindow:mWindow
                      completionHandler:^(NSInteger result){
                          if(result == NSFileHandlingPanelOKButton){
                            [self openImageURL: [[openPanel URLs] objectAtIndex: 0]];
                          }
                      }];
 
}


- (IBAction) sendAndroid : (id)sender
{
    [self initNetworkCommunication];
}


- (void)awakeFromNib
{
    NSLog(@"awakeFromNib");
    NSString * _path = [[NSBundle mainBundle] pathForResource: @"Qisda" ofType: @"jpg"];   //default picture
    NSURL * url = [NSURL fileURLWithPath: _path];
    [self openImageURL: url];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    NSLog(@"applicationDidFinishLaunching");
    
    NSArray *fileList = [[NSArray alloc] init];
    NSError *error = nil;
    fileManager = [NSFileManager defaultManager];
    fileList = [fileManager contentsOfDirectoryAtPath:[self pathToMonitor] error:&error];
    fileCount = [fileList count];  //update filecount
    
    self.directoryWatcher = [MHWDirectoryWatcher directoryWatcherAtPath:[self pathToMonitor] callback:^{[self directoryDidChange];}];
    
    
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                         forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    //Initiate ReceiveServer
    mReceiveServer = [[ReceivingFileServer alloc] init];
    [mReceiveServer setup];
    [mReceiveServer setview:self.view.window];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
}
/*
 * This is handler from share extension openURL
 */
- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSURL *mLauchURL = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
    NSLog(@"Launch url: %@", mLauchURL);
    
    //Initiate imageArray to receive from extension
    imageArray = [[NSMutableArray alloc] initWithArray:[self readUrlFromExtension]];
    [self processImageList];
}

- (NSMutableArray *)readUrlFromExtension{
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.image.share"];
    NSMutableArray *value = [shared valueForKey:@"url"];
    NSLog(@"readUrlFromExtension url: %@", value);
    return value;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    NSLog(@"applicationWillTerminate");
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return true;
}


@end
