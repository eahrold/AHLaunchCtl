//
//  main.m
//  rootTest
//
//  Created by Eldon on 2/22/15.
//  Copyright (c) 2015 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHLaunchCtl.h"

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        // insert code here...
        AHLaunchJob *_job = [[AHLaunchJob alloc] init];
        NSLog(@"Check initialization. %@", _job);

        _job = [AHLaunchJob new];
        _job.Label = @"com.eeaapps.echo.helloworld";
        _job.ProgramArguments = @[ @"/bin/echo", @"hello world" ];
        _job.StandardOutPath = @"/tmp/hello.txt";
        _job.RunAtLoad = YES;

        NSLog(@"Check initialization after property set. %@", _job);

        NSError *error = nil;
        if (![[AHLaunchCtl sharedController] add:_job
                                        toDomain:kAHGlobalLaunchDaemon
                                           error:&error]) {
            NSLog(@"Error Adding Job: %@", error.localizedDescription);

        } else {
            NSLog(@"should be YES%@", _job);
            if (![[AHLaunchCtl sharedController] remove:_job.Label
                                             fromDomain:kAHGlobalLaunchDaemon
                                                  error:&error]) {
                NSLog(@"Error Removing Job: %@", error.localizedDescription);
            }
        }
    }
    return 0;
}
