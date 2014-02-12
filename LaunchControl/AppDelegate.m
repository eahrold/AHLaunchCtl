//
//  AppDelegate.m
//  LaunchControl
//
//  Created by Eldon on 2/7/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import "AppDelegate.h"
#import "AHLaunchCtl.h"

@implementation AppDelegate
-(void)applicationWillTerminate:(NSNotification *)notification{
    [AHLaunchCtl quitHelper];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSError* error;
    [AHLaunchCtl installHelper:kAHLaunchCtlHelperName prompt:@"Install Helper?" error:&error];
    if(error){
        [NSApp presentError:error];
    }
}

- (IBAction)addJob:(id)sender {
    AHlaunchDomain domain;

    NSButton* b = _JobType.selectedCell;
    if([b.identifier intValue] == 1){
        domain = kAHUserLaunchAgent;
    }else if([b.identifier intValue] == 2){
        domain = kAHGlobalLaunchAgent;
    }else{
        domain = kAHGlobalLaunchDaemon;
    }
    
    AHLaunchJob *job = [AHLaunchJob new];
    job.Label = _label.stringValue;
    job.Program = _command.stringValue;
    job.ProgramArguments = @[@"hello"];
    job.StartInterval =  [_timer.stringValue integerValue];
    job.StandardOutPath = [NSString stringWithFormat:@"/tmp/%@.txt",_label.stringValue];
    job.RunAtLoad = YES;

    [[AHLaunchCtl sharedControler]add:job toDomain:domain reply:^(NSError *error) {
        if(error){
            NSLog(@"error: %@",error.localizedDescription);
        }else{
            NSLog(@"added job");
        }
    }];
}

- (IBAction)removeJob:(id)sender {
    AHlaunchDomain domain;
    
    NSButton* b = _JobType.selectedCell;
    if([b.identifier intValue] == 1)
        domain = kAHUserLaunchAgent;
    else if([b.identifier intValue] == 2)
        domain = kAHGlobalLaunchAgent;
    else
        domain = kAHGlobalLaunchDaemon;
    
    
    [[AHLaunchCtl sharedControler]remove:_label.stringValue fromDomain:domain reply:^(NSError *error) {
        if(error){
            NSLog(@"error: %@",error.localizedDescription);
        }else{
            NSLog(@"removed job");
        }
    }];
    
}

- (IBAction)authorize:(NSButton*)sender {
    AHLaunchCtl *controller = [AHLaunchCtl new];
    
    [controller authorizeSessionFor:10 error:^(NSError *error){
        if(error)
            NSLog(@"error: %@",error.localizedDescription);
        
    }timeRemaining:^(NSInteger time){
        if(time <= 0){
            _countdown.stringValue = @"expired";
        }else{
         [[NSOperationQueue mainQueue]addOperationWithBlock:^{
             _countdown.stringValue = [NSString stringWithFormat:@"%ld",time];
         }];
        }
    }];

}

- (IBAction)deauthorize:(id)sender {
    AHLaunchCtl *controller = [AHLaunchCtl new];
    [controller deAuthorizeSession:^(NSError *error) {
        if(error){
            NSLog(@"error: %@",error.localizedDescription);
        }else{
            NSLog(@"Deauthorized Session job");
        }
    }];
}

- (IBAction)uninstallHelper:(id)sender {
    [AHLaunchCtl uninstallHelper:kAHLaunchCtlHelperName reply:^(NSError *error) {
        if(error){
            [NSApp presentError:error];
        }else{
            NSLog(@"Helper Uninstaled");
        }
    }];
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{return YES;}

@end


