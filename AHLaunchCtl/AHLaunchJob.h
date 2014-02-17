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
typedef int AHLaunchDomain;

enum AHLaunchlDomains {
    /** User Launch Agents ~/Library/LaunchAgents 
        loaded by the Console user */
    kAHUserLaunchAgent = 1001,
    
    /** Administrator provided LaunchAgents /Library/LaunchAgents/ 
        loaded by the console user */
    kAHGlobalLaunchAgent,
    
    /** Apple provided LaunchDaemons /Library/LaunchAgents/
        loaded by root user */
    kAHSystemLaunchAgent,
    
    /** Administrator provided LaunchAgents /Library/LaunchDaemons/
        loaded by root user */
    kAHGlobalLaunchDaemon,
    
    /** Apple provided LaunchDaemons /Library/LaunchDaemons/
        loaded by root user */
    kAHSystemLaunchDaemon,
};

@interface AHLaunchJob : NSObject
@property (copy, nonatomic) NSString        *Label;
@property (nonatomic)       BOOL            Disabled;
#pragma mark -
@property (copy, nonatomic) NSString        *Program;
@property (copy, nonatomic) NSArray         *ProgramArguments;
@property (nonatomic)       NSInteger       StartInterval;
@property (copy, nonatomic) NSString        *ServiceDescription;
#pragma mark -
@property (copy, nonatomic) NSString        *UserName;
@property (copy, nonatomic) NSString        *GroupName;
@property (copy, nonatomic) NSDictionary    *inetdCompatibility; //
#pragma mark -
@property (copy, nonatomic) NSArray         *LimitLoadToHosts;
@property (copy, nonatomic) NSArray         *LimitLoadFromHosts;
@property (copy, nonatomic) NSString        *LimitLoadToSessionType;
#pragma mark -
@property (nonatomic) BOOL                  EnableGlobbing;
@property (nonatomic) BOOL                  EnableTransactions;
@property (nonatomic) BOOL                  BeginTransactionAtShutdown; //
#pragma mark -
/* KeepAlive dictionary or Number user @YES and @NO **/
@property (nonatomic) id                    KeepAlive;
@property (nonatomic) BOOL                  OnDemand;
@property (nonatomic) BOOL                  RunAtLoad;
#pragma mark -
@property (copy, nonatomic) NSString        *RootDirectory;
@property (copy, nonatomic) NSString        *WorkingDirectory;
#pragma mark -
@property (copy, nonatomic) NSDictionary    *EnvironmentVariables;
@property (nonatomic)       NSInteger       Umask;
@property (nonatomic)       NSInteger       TimeOut;
@property (nonatomic)       NSInteger       ExitTimeOut;
@property (nonatomic)       NSInteger       ThrottleInterval;
#pragma mark -
@property (nonatomic)       BOOL            InitGroups;
@property (copy, nonatomic) NSArray         *WatchPaths;
@property (copy, nonatomic) NSArray         *QueueDirectories;
@property (nonatomic)       BOOL            StartOnMount;
//dictionary of integers or array of dictionary of integers
@property (copy, nonatomic) id              StartCalendarInterval;
#pragma mark -
@property (copy, nonatomic) NSString        *StandardInPath;
@property (copy, nonatomic) NSString        *StandardOutPath;
@property (copy, nonatomic) NSString        *StandardErrorPath;
@property (nonatomic) BOOL                  Debug;
@property (nonatomic) BOOL                  WaitForDebugger;
#pragma mark -
@property (copy, nonatomic) NSDictionary    *SoftResourceLimits;//
@property (copy, nonatomic) NSDictionary    *HardResourceLimits;//
#pragma mark -
@property (nonatomic)       NSInteger       Nice;
@property (copy, nonatomic) NSString        *ProcessType;
#pragma mark -
@property (nonatomic)       BOOL            AbandonProcessGroup;//
@property (nonatomic)       BOOL            LowPriorityIO;
@property (nonatomic)       BOOL            LowPriorityBackgroundIO;
@property (nonatomic)       BOOL            LaunchOnlyOnce; ///
#pragma mark -
@property (copy, nonatomic) NSDictionary    *MachServices; //
@property (copy, nonatomic) NSDictionary    *Sockets; //
#pragma mark - Specialized / Undocumented Apple Keys
@property (copy, nonatomic) NSDictionary    *LaunchEvents;
@property (copy, nonatomic) NSDictionary    *PerJobMachServices;
@property (copy, nonatomic) NSString        *MachExceptionHandler;
#pragma mark -
@property (copy, nonatomic) NSString        *POSIXSpawnType;
@property (copy, nonatomic) NSString        *PosixSpawnType;
#pragma mark -
@property (nonatomic)       BOOL            ServiceIPC;
@property (nonatomic)       BOOL            XPCDomainBootstrapper;
#pragma mark -
@property (copy, nonatomic) NSString        *CFBundleIdentifier;
@property (copy, nonatomic) NSString        *SHAuthorizationRight;
#pragma mark -
@property (copy, nonatomic) NSDictionary    *JetsamProperties;
@property (copy, nonatomic) NSArray         *BinaryOrderPreference;
@property (nonatomic)       BOOL            SessionCreate;
@property (nonatomic)       BOOL            MultipleInstances;
#pragma mark -
@property (nonatomic)       BOOL            HopefullyExitsLast; //
@property (nonatomic)       BOOL            ShutdownMonitor;
@property (nonatomic)       BOOL            EventMonitor;
@property (nonatomic)       BOOL            IgnoreProcessGroupAtShutdown;
#pragma mark - Read only properties...
@property (nonatomic, readonly) AHLaunchDomain  domain;//
@property (nonatomic, readonly) NSInteger   PID;
@property (nonatomic, readonly) NSInteger   LastExitStatus;//
@property (nonatomic, readonly) BOOL        isCurrentlyLoaded;//
#pragma mark;
-(NSDictionary*)dictionary;
#pragma mark - Class Methods
+(AHLaunchJob*)jobFromDictionary:(NSDictionary*)dict;
+(AHLaunchJob*)jobFromFile:(NSString*)file;


@end

