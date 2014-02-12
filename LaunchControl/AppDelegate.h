//
//  AppDelegate.h
//  LaunchControl
//
//  Created by Eldon on 2/7/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class AHLaunchJob;

@interface AppDelegate : NSObject <NSApplicationDelegate>

- (IBAction)addJob:(id)sender;
- (IBAction)removeJob:(id)sender;
- (IBAction)authorize:(id)sender;
- (IBAction)deauthorize:(id)sender;

- (IBAction)uninstallHelper:(id)sender;

@property (assign) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSTextField *label;
@property (weak) IBOutlet NSTextField *command;
@property (weak) IBOutlet NSTextField *timer;
@property (weak) IBOutlet NSTextField *countdown;

@property (weak) IBOutlet NSMatrix *JobType;

@end
