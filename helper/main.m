//
//  main.m
//  helper
//
//  Created by Eldon on 2/7/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHLaunchCtlHelper.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        AHLaunchCtlXPCListener *helper = [[AHLaunchCtlXPCListener alloc]init];
        [helper run];
    }
	return 0;
}

