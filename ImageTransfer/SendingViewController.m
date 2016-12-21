//
//  SendingViewController.m
//  ImageTransfer
//
//  Created by LongHenry on 2016/3/15.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import "SendingViewController.h"
#import "NSView+APForwardDraggingDestination.h"


@implementation SendingViewController
@synthesize mResult;
@synthesize mFileName;
@synthesize mWindow;
@synthesize path;
@synthesize imageData;

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
    [mSendingClient initNetworkCommunication];
}


- (IBAction)openImage: (id)sender   //user open a new file from menubar
{
    NSOpenPanel * openPanel = [NSOpenPanel openPanel];
    NSString *    extensions = @"jpg/jpeg/JPG/JPEG/png/PNG";
    NSArray *     types = [extensions pathComponents];
    
    [openPanel setAllowedFileTypes: types];
    [openPanel beginSheetModalForWindow: mWindow
                      completionHandler:^(NSInteger result){
                          if(result == NSFileHandlingPanelOKButton){
                            [self openImageURL: [[openPanel URLs] objectAtIndex: 0]];
                            [mSendingClient initNetworkCommunication];
                          }
                      }];
 
}


- (IBAction) sendAndroid : (id)sender
{
    [mSendingClient initNetworkCommunication];
}


- (void)awakeFromNib
{
    NSLog(@"awakeFromNib");
    NSString * _path = [[NSBundle mainBundle] pathForResource: @"Qisda" ofType: @"jpg"];   //default picture
    NSURL * url = [NSURL fileURLWithPath: _path];
    [self openImageURL: url];
    
    // customize the IKImageView...
    [mImageView setDoubleClickOpensImageEditPanel: NO];
    [mImageView setCurrentToolMode: IKToolModeNone];
    [mImageView zoomImageToFit: self];
    mImageView.supportsDragAndDrop = FALSE;
    [mImageView setDelegate: self];
    [mImageView ap_forwardDraggingDestinationTo:self];
    [mImageView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}


- (void)openImageURL: (NSURL*)url
{
    NSLog(@"NSURL: %@",url);
    //[mImageView setImageWithURL: url];
    [self imageDrawing : url];
    [mImageView zoomImageToFit: self];
    

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
        [mImageView setImage: image
             imageProperties: mImageProperties];
        
        //[mWindow setTitleWithRepresentedFilename: [url path]];
        CGImageRelease(image);
    }
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSLog(@"draggingEntered!");
    return NSDragOperationGeneric;
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSString * extensions = @"jpg/jpeg/JPG/JPEG/png/PNG";
        NSArray * types = [extensions pathComponents];
        NSURL *fileURL = [NSURL URLFromPasteboard:pboard];
        
        BOOL isCorrectType = [types containsObject: [[fileURL path] pathExtension]];
        if (!isCorrectType){
            return NO;
        }
        [self openImageURL:fileURL];
    }
    return YES;
}

-(void)concludeDragOperation:(id)sender
{
    NSLog(@"concludeDragOperation");
    [mSendingClient initNetworkCommunication];
    [mImageView zoomImageToFit: self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    NSLog(@"applicationDidFinishLaunching");
    NSArray *fileList = [[NSArray alloc] init];
    NSError *error = nil;
    fileManager = [NSFileManager defaultManager];
    fileList = [fileManager contentsOfDirectoryAtPath:[self pathToMonitor] error:&error];
    fileCount = [fileList count];  //update filecount
    
    self.directoryWatcher = [MHWDirectoryWatcher
                             directoryWatcherAtPath:[self pathToMonitor] callback:^{[self directoryDidChange];}];
    

    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                         forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    
    //Initiate SendingClent
    mSendingClient = [[SendingFileClient alloc] init];
    [mSendingClient setview: self];
    
    //Check imageArray from extension if exist, then process it
    imageArray = [NSMutableArray arrayWithArray:[self readUrlFromExtension]];
    if(imageArray.count != 0)
        [self processImageList];
    
    //Initiate ReceiveServer
    mReceiveServer = [[ReceivingFileServer alloc] init];
    [mReceiveServer setup];
    [mReceiveServer setview: self.view.window];
}

/*
 * This is handler from share extension openURL
 */
- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSURL *mLauchURL = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
    NSLog(@"Launch url: %@", mLauchURL);
    imageArray = [NSMutableArray arrayWithArray:[self readUrlFromExtension]];
    if(imageArray.count != 0)
        [self processImageList];
}

- (NSUInteger) processImageList{
    NSLog(@"imageArray count: %ld", imageArray.count);
    NSUInteger mCount = imageArray.count;
    if(imageArray.count != 0){
        NSURL *imageURL = [NSURL fileURLWithPath: [imageArray objectAtIndex:0]]; //deliver first index
        [self openImageURL: imageURL];
        [mSendingClient initNetworkCommunication];
        [imageArray removeObjectAtIndex:0];
    }
    return mCount;
}


- (NSMutableArray *)readUrlFromExtension{
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.image.share"];
    NSMutableArray *value = [shared valueForKey:@"url"];
    NSLog(@"readUrlFromExtension url: %@", value);
    /*
    NSAlert *theAlert = [[NSAlert alloc] init];
    [theAlert setMessageText:@"readUrlFromExtension url!"];
    [theAlert setInformativeText:[NSString stringWithFormat:@"url %@",value]];
    [theAlert addButtonWithTitle:@"OK"];
    [theAlert beginSheetModalForWindow:[self.view window] completionHandler:^(NSInteger result) {
        NSLog(@"Alert Dialog Show");
    }];
    */
    [shared removeObjectForKey:@"url"];  // delete key after read
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
