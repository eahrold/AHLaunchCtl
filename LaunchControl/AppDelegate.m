//
//  AppDelegate.m
//  LaunchControl
//
//  Created by Eldon on 2/7/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import "AppDelegate.h"
#import "AHLaunchCtl.h"
#import "NSFileManger+Privileged.h"



@implementation AppDelegate{
    AHLaunchDomain domain;
}
-(void)applicationWillTerminate:(NSNotification *)notification{
    [AHLaunchCtl quitHelper];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    domain = [[(NSButton*)_JobType.selectedCell identifier]intValue];

}

- (IBAction)addJob:(id)sender {
    AHLaunchJob *job = [AHLaunchJob new];
    
    job.Label = _label.stringValue;
    
    NSArray* array = [_command.stringValue componentsSeparatedByString:@" "];
    assert(array != nil);
    
    job.ProgramArguments = array;
    job.OnDemand = YES;
    job.RunAtLoad = YES;
    
    job.StartInterval =  [_timer.stringValue integerValue];
    job.StandardOutPath = [NSString stringWithFormat:@"/tmp/%@.txt",_label.stringValue];
    job.KeepAlive = @YES;
    
    [[AHLaunchCtl sharedControler]add:job toDomain:domain overwrite:_overwrite.state reply:^(NSError *error) {
        if(error){
            [self logError:error];
        }else{
            [self logWithFormat:@"Added Job: %@",job];
        }
    }];
}

- (IBAction)removeJob:(id)sender {
    [[AHLaunchCtl sharedControler]remove:_label.stringValue fromDomain:domain reply:^(NSError *error) {
        if(error){
            [self logError:error];
        }else{
            [self logText:@"removed job"];

        }
    }];
    
}

-(IBAction)privlidgedCopy:(id)sender{
    NSError *error;
    [[NSFileManager defaultManager]copyItemAtPath:@"/tmp/test.txt" toPrivilegedLocation:@"/usr/local/test/" overwrite:YES error:&error];
    if(error)
        [self logError:error];
    else
        [self logText:@"Copied item"];
}

- (IBAction)load:(id)sender {
    [[AHLaunchCtl sharedControler]start:_label.stringValue inDomain:domain reply:^(NSError *error) {
        if(error)
            [self logError:error];
        else
            [self logText:@"Started LaunchD job"];
    }];
}

- (IBAction)unload:(id)sender {
    [[AHLaunchCtl sharedControler]stop:_label.stringValue inDomain:domain reply:^(NSError *error) {
        if(error)
            [self logError:error];
        else
            [self logText:@"Stopped LaunchD job"];
    }];
}


- (IBAction)authorize:(NSButton*)sender {
    AHLaunchCtl *controller = [AHLaunchCtl new];
    [controller authorizeSessionForNumberOfSeconds:60 timeRemaining:^(NSInteger time) {
        if(time <= 0){
            sender.title = @"Authorize";
        }else{
            [[NSOperationQueue mainQueue]addOperationWithBlock:^{
                sender.title = [NSString stringWithFormat:@"%ld",time];
            }];
        }
    } reply:^(NSError *error) {
        if(error)
            [self logError:error];
    }];
}

- (IBAction)deauthorize:(id)sender {
    AHLaunchCtl *controller = [AHLaunchCtl new];
    [controller deAuthorizeSession:^(NSError *error) {
        if(error){
            [self logError:error];
        }else{
            [self logText:@"Deauthorized Session job"];
        }
    }];
}



- (IBAction)uninstallHelper:(id)sender {
    [AHLaunchCtl uninstallAHLaunchCtlHelper:^(NSError *error) {
        if(error){
            [self logError:error];
        }else{
            [self logText:@"helper removed"];
        }
    }];
}

- (IBAction)installHelperTool:(id)sender {
    NSError* error;
    [AHLaunchCtl installHelper:kAHLaunchCtlHelperTool prompt:@"Install Helper?" error:&error];
    if(error){
        [self logError:error];
    }else{
        [self logText:@"helper installed"];
    }
}

- (IBAction)domainChanged:(NSMatrix *)sender {
    domain = [[(NSButton*)sender.selectedCell identifier]intValue];
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{return YES;}


#pragma mark - Logging
- (void)logText:(NSString *)text
{
    assert(text != nil);
    text = [text stringByAppendingString:@"\n\n"];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        BOOL scroll = (NSMaxY(self.logMessage.visibleRect) == NSMaxY(self.logMessage.bounds));
        
        [[self.logMessage textStorage] appendAttributedString:[[NSAttributedString alloc] initWithString:text]];
        
        if (scroll) // Scroll to end of the textview contents
            [self.logMessage scrollRangeToVisible: NSMakeRange(self.logMessage.string.length, 0)];
        
    }];
}

- (void)logWithFormat:(NSString *)format, ...
{
    va_list ap;
    assert(format != nil);
    va_start(ap, format);
    [self logText:[[NSString alloc] initWithFormat:format arguments:ap]];
    va_end(ap);
}

- (void)logError:(NSError *)error
{
    assert(error != nil);
    [self logWithFormat:@"error:[%@ - %d] %@ ", [error domain], (int) [error code],error.localizedDescription];
}

@end


