//  AHLaunchJob.h
//  Copyright (c) 2014 Eldon Ahrold ( https://github.com/eahrold/AHLaunchCtl )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.




#import <Foundation/Foundation.h>

@interface AHLaunchJob : NSObject <NSSecureCoding>
@property (copy, nonatomic) NSString * Label;
@property (copy, nonatomic) NSString * Program;
@property (copy, nonatomic) NSArray  * ProgramArguments;
@property (copy, nonatomic) NSDictionary * EnvironmentVariables;
@property (nonatomic)       NSInteger      StartInterval;
@property (copy, nonatomic) NSDictionary * StartCalendarInterval;
@property (copy, nonatomic) id             KeepAlive;
@property (copy, nonatomic) NSDictionary * WatchPaths;
@property (nonatomic) BOOL  StartOnMount;
@property (nonatomic) BOOL  RunAtLoad;
@property (nonatomic) BOOL  OnDemand;
@property (copy, nonatomic) NSString * UserName;
@property (copy, nonatomic) NSString * GroupName;
@property (copy, nonatomic) NSArray  * LimitLoadToHosts;
@property (copy, nonatomic) NSArray  * LimitLoadFromHosts;
@property (copy, nonatomic) NSString * LimitLoadToSessionType;
@property (copy, nonatomic) NSString * RootDirectory;
@property (copy, nonatomic) NSString * WorkingDirectory;
@property (copy, nonatomic) NSArray  * QueueDirectories;
@property (nonatomic) BOOL  EnableGlobbing;
@property (nonatomic) BOOL  InitGroups;
@property (nonatomic) BOOL  EnableTransactions;
@property (nonatomic) BOOL  Debug;
@property (nonatomic) BOOL  WaitForDebugger;
@property (nonatomic) NSInteger Nice;
@property (nonatomic) NSInteger Umask;
@property (nonatomic) NSInteger TimeOut;
@property (nonatomic) NSInteger ExitTimeOut;
@property (nonatomic) NSInteger ThrottleInterval;
@property (nonatomic) NSInteger LastExitStatus;
@property (copy, nonatomic) NSString *StandardInPath;
@property (copy, nonatomic) NSString *StandardOutPath;
@property (copy, nonatomic) NSString *StandardErrorPath;
@property (copy, readonly) NSMutableDictionary *dictionary;


-(NSDictionary*)dictionary;
+(AHLaunchJob*)jobFromDictionary:(NSDictionary*)dict;
+(AHLaunchJob*)jobFromFile:(NSString*)file;


@end

