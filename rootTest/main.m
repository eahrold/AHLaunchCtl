//
//  main.m
//  rootTest
//
//  Created by Eldon on 2/22/15.
//  Copyright (c) 2015 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHLaunchCtl.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        AHLaunchJob *job = [AHLaunchJob new];
        job = [AHLaunchJob new];
        job.Label = @"com.eeaapps.echo.helloworld";
        job.ProgramArguments = @[ @"/bin/echo", @"hello world" ];
        job.StandardOutPath = @"/tmp/hello.txt";
        job.RunAtLoad = YES;

        NSError *error = nil;
        if(![[AHLaunchCtl sharedController] add:job toDomain:kAHGlobalLaunchDaemon error:&error]){
            NSLog(@"Error Adding Job: %@", error.localizedDescription);
        } else {
            if(![[AHLaunchCtl sharedController] remove:job.Label  fromDomain:kAHGlobalLaunchDaemon error:&error]){
                NSLog(@"Error Removing Job: %@", error.localizedDescription);
            }
        }
    }
    return 0;
}
