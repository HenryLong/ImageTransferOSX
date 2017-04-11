//
//  ShareViewController.h
//  ImageShare
//
//  Created by LongHenry on 2016/11/25.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Social/Social.h>

@interface ShareViewController : SLComposeServiceViewController{
    NSString *fileName;
    NSMutableArray *arrayOfImage;
}


@end
