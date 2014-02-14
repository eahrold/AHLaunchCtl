//  AHLaunchJob.m
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



#import "AHLaunchJob.h"
#import <ServiceManagement/ServiceManagement.h>

@interface AHLaunchJob ()
@property (copy,readwrite)  NSMutableDictionary * dictionary;
@end

@implementation AHLaunchJob{
}

-(instancetype)init{
    self = [super init];
    if(self){
        // we create a dictionary here, and use setters to populate it
        // otherwise the BOOL keys would end up in every LaunchD.plist
        _dictionary = [[NSMutableDictionary alloc]initWithCapacity:31];
    }
    return self;
    
}

-(NSString *)description{
    return [NSString stringWithFormat:@"%@",_dictionary];
}


+(AHLaunchJob *)jobFromDictionary:(NSDictionary *)dict{
    @try {
        AHLaunchJob* job = [AHLaunchJob new];
        [job setValuesForKeysWithDictionary:dict];
        return job;

    }
    @catch (NSException *exception) {
        return nil;
    }
}

+(AHLaunchJob *)jobFromFile:(NSString *)file{
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:file];
    return [self jobFromDictionary:dict];
}

#pragma mark - Secure Coding
-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    NSSet* SAND = [NSSet setWithObjects:[NSArray class],[NSDictionary class],[NSString class],[NSNumber class], nil];
    NSSet* NAS = [NSSet setWithObjects:[NSNumber class],[NSArray class],[NSDictionary class],[NSString class],[NSNumber class], nil];

    if(self){
        _dictionary = [aDecoder decodeObjectOfClasses:SAND forKey:@"dictionary"];
        _Label = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"Label"];
        _Program = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"Program"];
        _ProgramArguments = [aDecoder decodeObjectOfClasses:NAS forKey:@"ProgramArguments"];
    }
    return self;
}

+(BOOL)supportsSecureCoding{return YES;}
-(void)encodeWithCoder:(NSCoder *)aEncoder{
    [aEncoder encodeObject:_dictionary forKey:@"dictionary"];
    [aEncoder encodeObject:_Label forKey:@"Label"];
    [aEncoder encodeObject:_Program forKey:@"Program"];
    [aEncoder encodeObject:_ProgramArguments forKey:@"ProgramArguments"];
}


#pragma mark - Setters
-(void)setLabel:(NSString *)Label{
    _Label = Label;
    [_dictionary setObject:_Label forKey:@"Label"];
}
-(void)setProgram:(NSString *)Program{
    _Program = Program;
    [_dictionary setObject:_Program forKey:@"Program"];
}

-(void)setProgramArguments:(NSArray *)ProgramArguments{
    _ProgramArguments = ProgramArguments;
    [_dictionary setObject:_ProgramArguments forKey:@"ProgramArguments"];
}

-(void)setEnvironmentVariables:(NSDictionary *)EnvironmentVariables{
    _EnvironmentVariables = EnvironmentVariables;
    [_dictionary setObject:_EnvironmentVariables
             forKey:@"EnvironmentVariables"];
}

-(void)setStartInterval:(NSInteger)StartInterval{
    _StartInterval = StartInterval;
    [_dictionary setObject:[NSNumber numberWithInteger:_StartInterval]
             forKey:@"StartInterval"];
}

-(void)setStartCalendarInterval:(NSDictionary *)StartCalendarInterval{
    _StartCalendarInterval = StartCalendarInterval;
    [_dictionary setObject:_StartCalendarInterval
             forKey:@"StartCalendarInterval"];
}
-(void)setKeepAlive:(id)KeepAlive{
    if([KeepAlive isKindOfClass:[NSDictionary class]]){
        [_dictionary setObject:_KeepAlive
                 forKey:@"KeepAlive"];
        _KeepAlive = KeepAlive;
    }else if (KeepAlive == [NSNumber numberWithBool:YES] ||
              KeepAlive == [NSNumber numberWithBool:NO]){
        [_dictionary setObject:_KeepAlive
                 forKey:@"KeepAlive"];
        _KeepAlive = KeepAlive;
    }
}

-(void)setWatchPaths:(NSArray *)WatchPaths{
    _WatchPaths = WatchPaths;
    [_dictionary setObject:_WatchPaths forKey:@"WatchPaths"];
}

-(void)setStartOnMount:(BOOL)StartOnMount{
    _StartOnMount = StartOnMount;
    [_dictionary setObject:[NSNumber numberWithBool:_StartOnMount]
             forKey:@"StartOnMount"];
}
-(void)setRunAtLoad:(BOOL)RunAtLoad{
    _RunAtLoad = RunAtLoad;
    [_dictionary setObject:[NSNumber numberWithBool:_RunAtLoad ]
             forKey:@"RunAtLoad"];
    
}
-(void)setOnDemand:(BOOL)OnDemand{
    _OnDemand = OnDemand;
    [_dictionary setObject:[NSNumber numberWithBool:_OnDemand]
             forKey:@"OnDemand"];
}

-(void)setUserName:(NSString *)UserName{
    _UserName = UserName;
    [_dictionary setObject:_UserName
                    forKey:@"UserName"];
}

-(void)setGroupName:(NSString *)GroupName{
    _GroupName = GroupName;
    [_dictionary setObject:GroupName
             forKey:@"GroupName"];
}

-(void)setLimitLoadToHosts:(NSArray *)LimitLoadToHosts{
    _LimitLoadToHosts = LimitLoadToHosts;
    [_dictionary setObject:LimitLoadToHosts
             forKey:@"LimitLoadToHosts"];
}

-(void)setLimitLoadFromHosts:(NSArray *)LimitLoadFromHosts{
    _LimitLoadFromHosts = LimitLoadFromHosts;
    [_dictionary setObject:LimitLoadFromHosts
             forKey:@"LimitLoadFromHosts"];
}

-(void)setRootDirectory:(NSString *)RootDirectory{
    _RootDirectory = RootDirectory;
    [_dictionary setObject:RootDirectory
             forKey:@"RootDirectory"];
}

-(void)setWorkingDirectory:(NSString *)WorkingDirectory{
    _WorkingDirectory = WorkingDirectory;
    [_dictionary setObject:WorkingDirectory
             forKey:@"WorkingDirectory"];
}

-(void)setQueueDirectories:(NSArray *)QueueDirectories{
    _QueueDirectories = QueueDirectories;
    [_dictionary setObject:QueueDirectories
             forKey:@"QueueDirectories"];
}

-(void)setEnableGlobbing:(BOOL)EnableGlobbing{
    _EnableGlobbing = EnableGlobbing;
    [_dictionary setObject:[NSNumber numberWithBool:EnableGlobbing ]
             forKey:@"EnableGlobbing"];
}

-(void)setInitGroups:(BOOL)InitGroups{
    _InitGroups = InitGroups;
    [_dictionary setObject:[NSNumber numberWithBool:InitGroups]
             forKey:@"InitGroups"];
}

-(void)setEnableTransactions:(BOOL)EnableTransactions{
    _EnableTransactions = EnableTransactions;
    [_dictionary setObject:[NSNumber numberWithBool:EnableTransactions]
             forKey:@"EnableTransactions"];
}

-(void)setDebug:(BOOL)Debug{
    _Debug = Debug;
    [_dictionary setObject:[NSNumber numberWithBool:Debug]
             forKey:@"Debug"];
}

-(void)setWaitForDebugger:(BOOL)WaitForDebugger{
    _WaitForDebugger = WaitForDebugger;
    [_dictionary setObject:[NSNumber numberWithBool:WaitForDebugger]
             forKey:@"WaitForDebugger"];
}

-(void)setNice:(NSInteger)Nice{
    _Nice = Nice;
    [_dictionary setObject:[NSNumber numberWithInteger:Nice]
             forKey:@"Nice"];
}

-(void)setUmask:(NSInteger)Umask{
    _Umask = Umask;
    [_dictionary setObject:[NSNumber numberWithInteger:Umask]
             forKey:@"Umask"];
}

-(void)setTimeOut:(NSInteger)TimeOut{
    _TimeOut = TimeOut;
    [_dictionary setObject:[NSNumber numberWithInteger:TimeOut]
             forKey:@"TimeOut"];
}

-(void)setExitTimeOut:(NSInteger)ExitTimeOut{
    [_dictionary setObject:[NSNumber numberWithInteger:ExitTimeOut]
             forKey:@"ExitTimeOut"];
}
-(void)setThrottleInterval:(NSInteger)ThrottleInterval{
    [_dictionary setObject:[NSNumber numberWithInteger:ThrottleInterval]
             forKey:@"ThrottleInterval"];
}

-(void)setStandardInPath:(NSString *)StandardInPath{
    _StandardInPath = StandardInPath;
    [_dictionary setObject:StandardInPath
                    forKey:@"StandardInPath"];
}

-(void)setStandardOutPath:(NSString *)StandardOutPath{
    _StandardOutPath = StandardOutPath;
    [_dictionary setObject:StandardOutPath
                    forKey:@"StandardOutPath"];
}

-(void)setStandardErrorPath:(NSString *)StandardErrorPath{
    _StandardErrorPath = StandardErrorPath;
    [_dictionary setObject:StandardErrorPath
                    forKey:@"StandardErrorPath"];
}

-(void)setMachServices:(NSDictionary *)MachServices{
    _MachServices = MachServices;
    [_dictionary setObject:MachServices
                    forKey:@"MachServices"];
}

@end
