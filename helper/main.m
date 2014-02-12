//
//  main.m
//  helper
//
//  Created by Eldon on 2/7/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHLaunchCtlHelper.h"

static const NSTimeInterval kHelperCheckInterval = 1.0; // how often to check whether to quit

int main(int argc, const char * argv[])
{
    AHLaunchCtlXPCListener *helper = [[AHLaunchCtlXPCListener alloc]initConnection];
    
    NSRunLoop * helperLoop = [NSRunLoop currentRunLoop];
    while (!helper.helperToolShouldQuit)
    {
        [helperLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:kHelperCheckInterval]];
    }

    return 0;

}

