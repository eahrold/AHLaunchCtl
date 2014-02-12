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
        _dictionary = [[NSMutableDictionary alloc]initWithCapacity:31];
    }
    return self;
    
}

-(NSString *)description{
    return [NSString stringWithFormat:@"%@",_dictionary];
}


+(AHLaunchJob *)jobFromDictionary:(NSDictionary *)dict{
    AHLaunchJob* job = [AHLaunchJob new];
    [job setValuesForKeysWithDictionary:dict];
    return job;
}

+(AHLaunchJob *)jobFromFile:(NSString *)file{
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:file];
    return [self jobFromDictionary:dict];
}

#pragma mark - Secure Coding
-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    NSSet* SAND = [NSSet setWithObjects:[NSArray class],[NSDictionary class],[NSString class],[NSNumber class], nil];

    if(self){
        _dictionary = [aDecoder decodeObjectOfClasses:SAND forKey:@"dictionary"];
        _Label = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"Label"];
//        _Program = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"Program"];
//        _ProgramArguments = [aDecoder decodeObjectOfClass:[NSArray class] forKey:@"ProgramArguments"];
//        _EnvironmentVariables = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"EnvironmentVariables"];
//        _StartInterval = [aDecoder decodeIntegerForKey:@"StartInterval"];
//        _StartCalendarInterval = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"StartCalendarInterval"];
//        _KeepAlive = [aDecoder decodeObjectOfClass:[NSDictionary class] forKey:@"KeepAlive"];
//        _WatchPaths = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"WatchPaths"];
//        
//        _StartOnMount = [aDecoder decodeBoolForKey:@"StartOnMount"];
//        _RunAtLoad = [aDecoder decodeBoolForKey:@"RunAtLoad"];
//        _OnDemand = [aDecoder decodeBoolForKey:@"OnDemand"];
//        _UserName = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"UserName"];
//        _GroupName = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"GroupName"];
//        
//        _LimitLoadToHosts = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"LimitLoadToHosts"];
//        _LimitLoadFromHosts = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"LimitLoadFromHosts"];
//        _LimitLoadToSessionType = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"LimitLoadToSessionType"];
//        
//        _RootDirectory = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"RootDirectory"];
//        _WorkingDirectory = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"WorkingDirectory"];
//        _QueueDirectories = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"QueueDirectories"];
//        
//        _EnableGlobbing = [aDecoder decodeBoolForKey:@"EnableGlobbing"];
//        _InitGroups = [aDecoder decodeBoolForKey:@"InitGroups"];
//        _EnableTransactions = [aDecoder decodeBoolForKey:@"EnableTransactions"];
//        _Debug = [aDecoder decodeBoolForKey:@"Debug"];
//        _WaitForDebugger = [aDecoder decodeBoolForKey:@"WaitForDebugger"];
//        
//        _Nice = [aDecoder decodeIntegerForKey:@"Nice"];
//        _Umask = [aDecoder decodeIntegerForKey:@"Umask"];
//        _TimeOut = [aDecoder decodeIntegerForKey:@"TimeOut"];
//        _ExitTimeOut = [aDecoder decodeIntegerForKey:@"ExitTimeOut"];
//        _ThrottleInterval = [aDecoder decodeIntegerForKey:@"ThrottleInterval"];
//        _LastExitStatus = [aDecoder decodeIntegerForKey:@"LastExitStatus"];
//        
//        _StandardInPath = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"StandardInPath"];
//        _StandardOutPath = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"StandardOutPath"];
//        _StandardErrorPath = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"StandardErrorPath"];
    }
    return self;
}

+(BOOL)supportsSecureCoding{return YES;}
-(void)encodeWithCoder:(NSCoder *)aEncoder{
    [aEncoder encodeObject:_dictionary forKey:@"dictionary"];
    [aEncoder encodeObject:_Label forKey:@"Label"];
//    [aEncoder encodeObject:_Program forKey:@"Program"];
//    [aEncoder encodeObject:_ProgramArguments forKey:@"ProgramArguments"];
//    [aEncoder encodeObject:_EnvironmentVariables forKey:@"EnvironmentVariables"];
//    [aEncoder encodeInteger:_StartInterval forKey:@"StartInterval"];
//    [aEncoder encodeObject:_StartCalendarInterval forKey:@"StartCalendarInterval"];
//    [aEncoder encodeObject:_KeepAlive forKey:@"KeepAlive"];
//    [aEncoder encodeObject:_WatchPaths forKey:@"WatchPaths"];
//    
//    [aEncoder encodeBool:_StartOnMount forKey:@"StartOnMount"];
//    [aEncoder encodeBool:_RunAtLoad forKey:@"RunAtLoad"];
//    [aEncoder encodeBool:_OnDemand forKey:@"OnDemand"];
//    
//    [aEncoder encodeObject:_UserName forKey:@"UserName"];
//    [aEncoder encodeObject:_GroupName forKey:@"GroupName"];
//    [aEncoder encodeObject:_LimitLoadToHosts forKey:@"LimitLoadToHosts"];
//    [aEncoder encodeObject:_LimitLoadFromHosts forKey:@"LimitLoadFromHosts"];
//    [aEncoder encodeObject:_LimitLoadToSessionType forKey:@"LimitLoadToSessionType"];
//    [aEncoder encodeObject:_RootDirectory forKey:@"RootDirectory"];
//    [aEncoder encodeObject:_WorkingDirectory forKey:@"WorkingDirectory"];
//    [aEncoder encodeObject:_QueueDirectories forKey:@"QueueDirectories"];
//    
//    [aEncoder encodeBool:_EnableGlobbing forKey:@"EnableGlobbing"];
//    [aEncoder encodeBool:_InitGroups forKey:@"InitGroups"];
//    [aEncoder encodeBool:_EnableTransactions forKey:@"EnableTransactions"];
//    [aEncoder encodeBool:_Debug forKey:@"Debug"];
//    [aEncoder encodeBool:_WaitForDebugger forKey:@"WaitForDebugger"];
//    
//    [aEncoder encodeInteger:_Nice forKey:@"Nice"];
//    [aEncoder encodeInteger:_Umask forKey:@"Umask"];
//    [aEncoder encodeInteger:_TimeOut forKey:@"TimeOut"];
//    [aEncoder encodeInteger:_ExitTimeOut forKey:@"ExitTimeOut"];
//    [aEncoder encodeInteger:_ThrottleInterval forKey:@"ThrottleInterval"];
//    [aEncoder encodeInteger:_LastExitStatus forKey:@"LastExitStatus"];
//    
//    [aEncoder encodeObject:_StandardInPath forKey:@"StandardInPath"];
//    [aEncoder encodeObject:_StandardOutPath forKey:@"StandardOutPath"];
//    [aEncoder encodeObject:_StandardErrorPath forKey:@"StandardErrorPath"];
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

-(void)setWatchPaths:(NSDictionary *)WatchPaths{
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


@end
