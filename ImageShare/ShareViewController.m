//
//  ShareViewController.m
//  ImageShare
//
//  Created by LongHenry on 2016/11/25.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import "ShareViewController.h"
#import <CoreFoundation/CFStream.h>
#import <Foundation/NSRunLoop.h>
//#import "SendingViewController.h"


@implementation ShareViewController

- (void)loadView {
    [super loadView];
    isCancel = FALSE;
    arrayOfImage = [[NSMutableArray alloc] init];
    // Insert code here to customize the view
    self.title = NSLocalizedString(@"ImageShare", @"Title of the Social Service");
    
    NSLog(@"Input Items = %@", self.extensionContext.inputItems);
    NSString *typeIdentifier = (NSString *)kUTTypeURL; //kUTTypeImage;
    //NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
    //NSItemProvider *itemProvider = item.attachments.firstObject;
    for (NSExtensionItem *item in self.extensionContext.inputItems){
        for (NSItemProvider *itemProvider in item.attachments){
            if ([itemProvider hasItemConformingToTypeIdentifier:typeIdentifier]) {
                [itemProvider loadItemForTypeIdentifier:typeIdentifier
                                                options:nil
                                      completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                                          if(error){
                                              NSLog(@"Error retrieving: %@", error);
                                          }else {
                                              if([(NSObject*)item isKindOfClass:[NSURL class]]) {
                                                  fileName = [(NSURL*)item lastPathComponent];
                                                  NSLog(@"fileName: %@",fileName);
                                                  NSURL* url = (NSURL*)item;
                                                  [self insertURLtoArray :[url path]];
                                              } //end if([(NSObject*)item isKindOfClass:[NSURL class]])
                                          }
                                      }];
            }
        }
    }

}

- (void) viewDidLoad {
    [super viewDidLoad];
    [self.textView setEditable : NO];  //not allow user edit text
}

- (void)didSelectPost {
    // Perform the post operation
    // When the operation is complete (probably asynchronously), the service should notify the success or failure as well as the items that were actually shared
   [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
    
}


- (void)didSelectCancel {
    // Cleanup
    // Notify the Service was cancelled
    isCancel = TRUE;
    NSError *cancelError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    [self.extensionContext cancelRequestWithError:cancelError];
}


- (BOOL)isContentValid {
    NSLog(@"isContentValid");

    NSString * description =@"";
    NSString * extensions = @"jpg/jpeg/JPG/JPEG/png/PNG";
    NSArray * types = [extensions pathComponents];
    for (NSString *file in arrayOfImage){
        description = [NSString stringWithFormat:@"%@%@\n", description, file];
        BOOL isCorrectType = [types containsObject: [file pathExtension]];
        if (!isCorrectType){
            self.textView.string = @"Format Not Allow! JPG/PNG Only";
            return NO;
        }
    }
    self.textView.string = description;
    
    /*
    NSInteger messageLength = [[self.contentText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length];
    NSInteger charactersRemaining = 140 - messageLength;
    self.charactersRemaining = @(charactersRemaining);
    
    if (charactersRemaining >= 0) {
        return YES;
    }
    */
    
    return YES;
}


- (void)viewDidDisappear {
    NSLog(@"viewDidDisappear");
    if(!isCancel){
        [self saveUrlFromExtension];
        //Using NSWorkspace instead
        if (![[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"ImageShare://"]]) {
            [[self extensionContext] openURL:[NSURL URLWithString:@"ImageShare://"] completionHandler:^(BOOL success) {
            NSLog(@"Success? %i", success);
        }];
        } else {
            NSLog(@"Success!");
        }
    }
}

- (void) insertURLtoArray: (NSString*)fileUrl {
    [arrayOfImage addObject:fileUrl];
}

- (void)saveUrlFromExtension {
    
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.image.share"];
    [shared setObject:arrayOfImage forKey:@"url"];
    [shared synchronize];
}

@end
