//  AHLaunchCtl.m
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

#import "AHLaunchCtl.h"
#import "AHAuthorizedLaunchCtl.h"
#import "AHLaunchCtlHelper.h"
#import "AHAuthorizer.h"

#import <ServiceManagement/ServiceManagement.h>
#import <SystemConfiguration/SystemConfiguration.h>

NSString* const kAHLaunchCtlHelperTool = @"com.eeaapps.launchctl.helper";

static NSString * errorMsgFromCode(NSInteger code);
static NSString * launchFileDirectory(AHLaunchDomain domain);
static NSString * launchFile(NSString* label, AHLaunchDomain domain);
static BOOL jobIsRunning(NSString* label, AHLaunchDomain domain);
static BOOL jobExists(NSString* label, AHLaunchDomain domain);
static BOOL setToConsoleUser();
static BOOL resetToOriginalUser(uid_t uid);

enum LaunchControlErrorCodes
{
    kAHErrorJobLabelNotValid  = 1001,
    kAHErrorJobMissingRequiredKeys,
    
    kAHErrorJobNotLoaded,
    kAHErrorJobAlreayExists,
    kAHErrorJobAlreayLoaded,
    kAHErrorCouldNotLoadJob,
    kAHErrorCouldNotUnloadJob,
    kAHErrorJobCouldNotReload,

    kAHErrorFileNotFound,
    kAHErrorCouldNotWriteFile,
    kAHErrorMultipleJobsMatching,
    kAHErrorInsufficentPriviledges,
    kAHErrorExecutingAsIncorrectUser,
    kAHErrorProgramNotExecutable,
};

@interface AHLaunchJob () <NSSecureCoding>
@property (nonatomic, readwrite)     AHLaunchDomain  domain;//
@end

#pragma mark - Launch Controller
@implementation AHLaunchCtl{
}

+(AHLaunchCtl *)sharedControler{
    static dispatch_once_t onceToken;
    static AHLaunchCtl *shared;
    dispatch_once(&onceToken, ^{
        shared = [AHLaunchCtl new];
    });
    return shared;
}


#pragma mark - Public Methods
#pragma mark --- Add / Remove ---
-(void)add:(AHLaunchJob*)job toDomain:(AHLaunchDomain)domain overwrite:(BOOL)overwrite reply:(void (^)(NSError* error))reply{
    NSError* error;
    if(!overwrite && jobExists(job.Label,domain)){
        [[self class]errorWithCode:kAHErrorJobAlreayExists error:&error];
        reply(error);
        return;
    }
       
    if(domain > kAHUserLaunchAgent){
        AHAuthorizedLaunchCtl *controller = [[AHAuthorizedLaunchCtl alloc]init];
        NSData* authData = [ AHAuthorizer authorizeHelper];
        assert(authData != nil);
        [controller connectToHelper];
        [[controller.connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
            reply(error);
        }]addJob:job toDomain:domain authData:authData reply:^(NSError *error) {
            [controller.connection invalidate];
            if(!error){
                if(domain <= kAHSystemLaunchAgent){
                    [self load:job inDomain:domain error:&error];
                }
            }
            reply(error);
        }];
    }else{
        [self add:job toDomain:domain error:&error];
        reply(error);
    }
}

-(void)remove:(NSString*)label fromDomain:(AHLaunchDomain)domain reply:(void (^)(NSError* error))reply{
    if(domain > kAHUserLaunchAgent){
        AHAuthorizedLaunchCtl *controller = [[AHAuthorizedLaunchCtl alloc]init];
        NSData* authData = [AHAuthorizer authorizeHelper];
        assert(authData != nil);
        [controller connectToHelper];
        [[controller.connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
            reply(error);
        }]removeJob:label fromDomain:domain authData:authData reply:^(NSError *error) {
            [controller.connection invalidate];
            if(!error){
                if(domain <= kAHSystemLaunchAgent){
                    [self unload:label inDomain:domain error:&error];
                }
            }
            reply(error);
        }];
    }else{
        NSError* error;
        [self remove:label fromDomain:domain error:&error];
        reply(error);
    }
}

-(void)start:(NSString *)label inDomain:(AHLaunchDomain)domain reply:(void (^)(NSError *))reply{
    if(jobIsRunning(kAHLaunchCtlHelperTool, kAHGlobalLaunchDaemon) && domain > kAHGlobalLaunchAgent){
        AHAuthorizedLaunchCtl *controller = [[AHAuthorizedLaunchCtl alloc]init];
        NSData* authData = [AHAuthorizer authorizeHelper];
        [controller connectToHelper];
        [[controller.connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
            [self start:label inDomain:domain error:&error];
            reply(error);
        }]startJob:label inDomain:domain authData:authData reply:^(NSError *error) {
            reply(error);
        }];
        
    }else{
        NSError *error;
        [self start:label inDomain:domain error:&error];
        reply(error);
    }
}

-(void)stop:(NSString *)label inDomain:(AHLaunchDomain)domain reply:(void (^)(NSError *))reply{
    if(jobIsRunning(kAHLaunchCtlHelperTool, kAHGlobalLaunchDaemon) && domain > kAHGlobalLaunchAgent){
        AHAuthorizedLaunchCtl *controller = [[AHAuthorizedLaunchCtl alloc]init];
        NSData* authData = [AHAuthorizer authorizeHelper];
        [controller connectToHelper];
        [[controller.connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
            [self stop:label inDomain:domain error:&error];
            reply(error);
        }]stopJob:label inDomain:domain authData:authData reply:^(NSError *error) {
            reply(error);
        }];
    }else{
        NSError *error;
        [self stop:label inDomain:domain error:&error];
        reply(error);
    }
}

-(void)restart:(NSString *)label inDomain:(AHLaunchDomain)domain status:(void (^)(NSString *))status reply:(void (^)(NSError *))reply{
    if(jobIsRunning(kAHLaunchCtlHelperTool, kAHGlobalLaunchDaemon) && domain > kAHGlobalLaunchAgent){
        AHAuthorizedLaunchCtl *controller = [[AHAuthorizedLaunchCtl alloc]init];
        NSData* authData = [AHAuthorizer authorizeHelper];
        [controller connectToHelper];
        [[controller.connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
            [self restart:label inDomain:domain error:&error];
            reply(error);
        }]restartJob:label inDomain:domain authData:authData reply:^(NSError *error) {
            reply(error);
        }];
    }else{
        NSError *error;
        status(@"Stopping Job");
        [self stop:label inDomain:domain error:&error];
        if(error){
            status(error.localizedDescription);
        }
        
        status(@"Starting Job");
        [self start:label inDomain:domain error:&error];
        reply(error);
    }
}
#pragma mark --- Authorization ---
-(void)authorizeSessionForNumberOfSeconds:(NSInteger)seconds
                            timeRemaining:(void (^)(NSInteger time))timeRemaining
                                    reply:(void (^)(NSError *error))reply;
{
    AHAuthorizedLaunchCtl *controller = [[AHAuthorizedLaunchCtl alloc]initWithTimeReplyBlock:timeRemaining];
    
    NSData* authData = [AHAuthorizer authorizeHelper];

    assert(authData != nil);
    [controller connectToHelper];
    
    [[controller.connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        reply(error);
    }]authorizeSessionFor:seconds authData:authData reply:^(NSError *error) {
        reply(error);
    }];
}

-(void)deAuthorizeSession:(void (^)(NSError *))reply{
    AHAuthorizedLaunchCtl *controller = [[AHAuthorizedLaunchCtl alloc]init];
    [controller connectToHelper];
    [[controller.connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        reply(error);
    }]deAuthorizeSession:^(NSError *error) {
        reply(error);
        [controller.connection invalidate];
    }];
}

#pragma mark - Private Methods
#pragma mark --- Add/Remove ---

/** The Add and Remove methods here should only be used when developing a cli tool, since they set the euid. They will not function properly with a helper tool since the helper tool is managed by laucnhd. https://developer.apple.com/library/mac/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html */

-(BOOL)add:(AHLaunchJob*)job toDomain:(AHLaunchDomain)domain error:(NSError *__autoreleasing *)error{
    uid_t uid = getuid();
    BOOL rc = NO;
    if(domain > kAHUserLaunchAgent){
        job = [AHLaunchJob jobFromDictionary:job.dictionary];
    }
    
    if(!job.Label){
        return [[self class] errorWithCode:kAHErrorJobMissingRequiredKeys error:error];
    }
    
    if([self writeJobToFile:job inDomain:domain error:error]){
        if(domain < kAHGlobalLaunchDaemon){
            if(!setToConsoleUser())
                return [[self class]errorWithCode:kAHErrorExecutingAsIncorrectUser error:error];
        }
        rc = [self load:job inDomain:domain error:error];
        resetToOriginalUser(uid);
    }
    return rc;
}

-(BOOL)remove:(NSString*)label fromDomain:(AHLaunchDomain)domain error:(NSError *__autoreleasing *)error{
    uid_t uid = getuid();
    if(domain < kAHGlobalLaunchDaemon){
        if(!setToConsoleUser())
            return [[self class]errorWithCode:kAHErrorExecutingAsIncorrectUser error:error];
    }
    [self unload:label inDomain:domain error:error];
    resetToOriginalUser(uid);
    return [self removeJobFileWithLabel:label domain:domain error:error];
}


#pragma mark --- Load / Unload Jobs ---
-(BOOL)load:(AHLaunchJob*)job inDomain:(AHLaunchDomain)domain error:(NSError *__autoreleasing *)error{
    BOOL rc;
    CFErrorRef cfError = NULL;
    AuthorizationRef authRef = NULL;

    if(domain >= kAHSystemLaunchAgent)
        [AHAuthorizer authorizeSystemDaemon:@"Load Job?" authRef:&authRef];

    rc =  SMJobSubmit(SMDomain(domain),
                      (__bridge CFDictionaryRef)job.dictionary,
                      authRef,
                      &cfError);
    
    if(!rc){
        [[self class] errorWithCFError:cfError code:1 error:error];
    }else{
        job.domain = domain;
    }
    
    [AHAuthorizer authoriztionFree:authRef];

    return rc;
}

-(BOOL)unload:(NSString*)label inDomain:(AHLaunchDomain)domain error:(NSError *__autoreleasing *)error{
    
    if(!jobIsRunning(label, domain)){
        return [[self class]errorWithCode:kAHErrorJobNotLoaded error:error];
    }
    
    BOOL rc;
    AuthorizationRef authRef = NULL;
    CFErrorRef cfError = NULL;

    if(domain >= kAHSystemLaunchAgent)
        [AHAuthorizer authorizeSystemDaemon:@"Unoad Job?" authRef:&authRef];

    rc =  SMJobRemove(SMDomain(domain),
                      (__bridge CFStringRef)label,
                      authRef,
                      YES,
                      &cfError);
    
    [AHAuthorizer authoriztionFree:authRef];
    
    if(!rc){
        [[self class] errorWithCFError:cfError code:1 error:error];
    }
    
    return rc;
}

-(BOOL)reload:(AHLaunchJob*)job inDomain:(AHLaunchDomain)domain error:(NSError *__autoreleasing *)error{
    if(jobIsRunning(job.Label, domain)){
        if(![self unload:job.Label inDomain:domain error:error]){
            return [[self class]errorWithCode:kAHErrorJobCouldNotReload error:error];
        }
    }
    return [self load:job inDomain:domain error:error];
}

#pragma mark --- Start / Stop / Restart ---
-(BOOL)start:(NSString*)label inDomain:(AHLaunchDomain)domain error:(NSError*__autoreleasing*)error{
    if(jobIsRunning(label, domain)){
        return [[self class] errorWithCode:kAHErrorJobAlreayLoaded error:error];
    }
    
    AHLaunchJob* job = [[self class]jobFromFileNamed:label inDomain:domain];
    if(job){
        return [self load:job inDomain:domain error:error];
    }else{
        return [[self class] errorWithCode:kAHErrorFileNotFound error:error];
    }
}

-(BOOL)stop:(NSString*)label inDomain:(AHLaunchDomain)domain error:(NSError*__autoreleasing*)error{
    return [self unload:label inDomain:domain error:error];
}

-(BOOL)restart:(NSString*)label inDomain:(AHLaunchDomain)domain error:(NSError *__autoreleasing *)error{
    AHLaunchJob *job = [[self class]jobFromRunningJobWithLabel:label inDomain:domain];
    if(!job){
        return [[self class]errorWithCode:kAHErrorJobNotLoaded error:error];
    }
    return [self reload:job inDomain:domain error:error];
}

-(BOOL)shouldLoadJob:(BOOL)load shouldStick:(BOOL)wKey label:(NSString*)label domain:(AHLaunchDomain)domain error:(NSError *__autoreleasing*)error{
    NSTask *task = [NSTask new];
    task.launchPath = @"/bin/launchctl";
    NSMutableArray* args = [[NSMutableArray alloc]initWithCapacity:3];
    if(load){
        [args addObjectsFromArray:@[@"load",launchFile(label, domain)]];
    }else{
        [args addObjectsFromArray:@[@"remove",label]];
    }
    
    if(wKey)[args insertObject:@"-w" atIndex:1];
    task.arguments = args;
    
    [task launch];
    [task waitUntilExit];
    if(task.terminationStatus != 0){
        if(load)
            return [[self class]errorWithCode:kAHErrorCouldNotLoadJob error:error];
        
        return [[self class]errorWithCode:kAHErrorCouldNotUnloadJob error:error];
    }
    return YES;
}


#pragma mark --- File Writing ---
-(BOOL)writeJobToFile:(AHLaunchJob*)job inDomain:(AHLaunchDomain)domain error:(NSError*__autoreleasing*)error{
    NSFileManager* fm = [NSFileManager new];
    
    BOOL rc = NO;
    if(![fm isExecutableFileAtPath:job.Program]){
        if([job.ProgramArguments objectAtIndex:0]){
            if(![fm isExecutableFileAtPath:job.ProgramArguments[0]]){
                return [[self class]errorWithCode:kAHErrorProgramNotExecutable error:error ];
            }
        }else{
            return NO;
        }
    }
    
    NSString* file = launchFile(job.Label, domain);
    rc = [job.dictionary writeToFile:file atomically:YES];
    if(!rc){
        return [[self class]errorWithCode:kAHErrorCouldNotWriteFile error:error];
    };
    
    if(domain > kAHUserLaunchAgent){
        rc = [fm setAttributes:@{NSFilePosixPermissions:[NSNumber numberWithInt:0644],
                                 NSFileOwnerAccountName:@"root",
                                 NSFileGroupOwnerAccountName:@"wheel"}
                  ofItemAtPath:file
                         error:error];
    }
    return rc;
}

-(BOOL)removeJobFileWithLabel:(NSString*)label domain:(AHLaunchDomain)domain error:(NSError*__autoreleasing*)error{
    NSFileManager* fm = [NSFileManager new];
    NSString* file = launchFile(label, domain);
    if([fm fileExistsAtPath:file isDirectory:NO]){
        return [fm removeItemAtPath:file error:error];
    }else{
        return YES;
    }
}

#pragma mark - Helper Tool Installation / Removal
+(BOOL)installHelper:(NSString *)label prompt:(NSString*)prompt error:(NSError *__autoreleasing *)error{
    AuthorizationRef authRef = NULL;
    OSStatus status;
    BOOL rc = YES;
    
    rc = [AHAuthorizer authorizeSMJobBless:prompt authRef:&authRef];
    
    if (!rc) {
        [[self class]errorWithCode:kAHErrorCouldNotLoadJob error:error];
    }else {
        CFErrorRef  cfError;
        status = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)label, authRef, &cfError);
        if (status != errAuthorizationSuccess) {
            [[self class]errorWithCFError:cfError code:1 error:error];
            rc = NO;
        }
    }
    [AHAuthorizer authoriztionFree:authRef];
    return rc;
}

+(void)uninstallHelper:(NSString *)label reply:(void (^)(NSError *))reply{
    AHAuthorizedLaunchCtl *controller = [[AHAuthorizedLaunchCtl alloc]init];
    [controller connectToHelper];
    
    NSData* authData = [AHAuthorizer authorizeHelper];
    assert(authData != nil);
    [[controller.connection remoteObjectProxy] uninstallHelper:label authData:authData reply:^(NSError *error) {
        reply(error);
    }];
}

+(void)quitHelper{
    AHAuthorizedLaunchCtl *controller = [[AHAuthorizedLaunchCtl alloc]init];
    [controller connectToHelper];
    
    [[controller.connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        NSLog(@"Error: %@ ",error.debugDescription);
    }]quitHelper];
}

#pragma mark - Convience Accessors
+(BOOL)launchAtLogin:(NSString*)app launch:(BOOL)launch global:(BOOL)global keepAlive:(BOOL)keepAlive error:(NSError*__autoreleasing*)error
{
    NSBundle* appBundle = [NSBundle bundleWithPath:app];
    NSString* appIdentifier = [NSString stringWithFormat:@"%@.launcher",appBundle.bundleIdentifier];
    
    AHLaunchCtl *controller = [AHLaunchCtl new];
    AHLaunchJob* job = [AHLaunchJob new];
    job.label = appIdentifier;
    job.program = appBundle.executablePath;
    job.runAtLoad = YES;
    job.keepAlive = @{@"SuccessfulExit":[NSNumber numberWithBool:keepAlive]};
    
    AHLaunchDomain domain = global ? kAHGlobalLaunchAgent:kAHUserLaunchAgent;
    return [controller load:job inDomain:domain error:error];
}

+(void)scheduleJob:(NSString*)label program:(NSString*)program interval:(int)seconds domain:(AHLaunchDomain)domain reply:(void (^)(NSError* error))reply
{
    [self scheduleJob:label program:program programArguments:nil interval:seconds domain:domain reply:^(NSError *error) {
        reply(error);
    }];
}

+(void)scheduleJob:(NSString*)label program:(NSString*)program programArguments:(NSArray*)programArguments interval:(int)seconds domain:(AHLaunchDomain)domain reply:(void (^)(NSError* error))reply
{
    AHLaunchCtl *controller = [AHLaunchCtl new];
    AHLaunchJob* job = [AHLaunchJob new];
    job.Label = label;
    job.Program = program;
    job.ProgramArguments = programArguments;
    job.RunAtLoad = YES;
    job.StartInterval = seconds;
    
    [controller add:job toDomain:domain overwrite:YES reply:^(NSError *error) {
        reply(error);
    }];
}


+(BOOL)restartJobMatching:(NSString *)match restartAll:(BOOL)restartAll{
    AHLaunchCtl* launchctl = [[AHLaunchCtl alloc]init];
    NSArray *jobList = [AHLaunchCtl allRunningJobsMatching:match];
    if(!restartAll){
        if(jobList.count > 0)
            return [[self class] errorWithCode:kAHErrorMultipleJobsMatching error:nil];
    }
    
    for(AHLaunchJob* job in jobList){
        [launchctl restart:job.Label inDomain:kAHSearchDomain error:nil];
    }
    
    return jobList.count > 0 ? YES:NO;
}

#pragma mark --- Get Job ---
+(AHLaunchJob *)jobFromFileNamed:(NSString *)label
                        inDomain:(AHLaunchDomain)domain
{
    NSArray *jobs = [self allJobsFromFilesInDomain:domain];
    if([label.pathExtension isEqualToString:@"plist"])
        label = [label stringByDeletingPathExtension];
    
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"%@ == SELF.Label ",label];

    for(AHLaunchJob *  job in jobs){
        if([predicate evaluateWithObject:job]){
            return job;
        }
    }
    return nil;
}

+(AHLaunchJob *)jobFromRunningJobWithLabel:(NSString *)label
                                  inDomain:(AHLaunchDomain)domain
{
    AHLaunchJob *job;
    NSDictionary* dict =  AHJobCopyDictionary(domain, label);
    // for some system processes the dict can return nil, so we have a more expensive back-up in that case;
    if(dict.count){
        job = [AHLaunchJob jobFromDictionary:dict];
    }else{
        job = [[[self class]runningJobMatching:label inDomain:domain] lastObject];
    }
    
    return job;
}

#pragma mark --- Get Array Of Jobs ---
+(NSArray*)allRunningJobsInDomain:(AHLaunchDomain)domain
{
    return [self jobMatch:nil domain:domain];
}

+(NSArray*)runningJobMatching:(NSString*)match inDomain:(AHLaunchDomain)domain
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"SELF.Label CONTAINS[c] %@ OR SELF.Program CONTAINS[c] %@",match,match];
    return [self jobMatch:predicate domain:domain];
}

+(NSArray*)allRunningJobsMatching:(NSString*)match{
    NSMutableArray * jobs  = [[NSMutableArray alloc]init];
    
    [jobs addObjectsFromArray:[[self class] runningJobMatching:match
                                                      inDomain:kAHUserLaunchAgent]];
    [jobs addObjectsFromArray:[[self class] runningJobMatching:match
                                                      inDomain:kAHGlobalLaunchDaemon]];
    
    return [NSArray arrayWithArray:jobs];
}

+(NSArray *)allJobsFromFilesMatching:(NSString*)match{
    NSMutableArray * jobs  = [[NSMutableArray alloc]init];
    AHLaunchDomain i;
    for (i=kAHUserLaunchAgent; i<=kAHSystemLaunchDaemon; i++){
        AHLaunchJob *job = [[self class] jobFromFileNamed:match inDomain:i];
        if(job)
            [jobs addObject:job];
    }
   
    return [NSArray arrayWithArray:jobs];
}

+(NSArray*)allJobsFromFilesInDomain:(AHLaunchDomain)domain{
    AHLaunchJob* job;
    NSMutableArray *jobs;
    NSString * launchDirectory = launchFileDirectory(domain);
    NSArray  * launchFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:launchDirectory
                                                                                 error:nil];
    
    if(launchFiles.count){
        jobs = [[NSMutableArray alloc]initWithCapacity:launchFiles.count];
    }
    
    for(NSString * file in launchFiles){
        NSString * filePath = [NSString stringWithFormat:@"%@/%@",launchDirectory,file];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
        if(dict){
            @try {
                job = [AHLaunchJob jobFromDictionary:dict];
                if(job)
                    job.domain = domain;
                    [jobs addObject:job];
            }
            @catch (NSException *exception) {
                NSLog(@"error %@",exception);
            }
        }
    }
    return jobs;
}


+(NSArray*)jobMatch:(NSPredicate*)predicate domain:(AHLaunchDomain)domain{
    NSArray* array = CFBridgingRelease(SMCopyAllJobDictionaries(SMDomain(domain)));
    if(!array.count)return nil;
    
    NSMutableArray *jobs = [[NSMutableArray alloc]initWithCapacity:array.count];
    for(NSDictionary* dict in array){
        AHLaunchJob* job;
        if(predicate){
            if([predicate evaluateWithObject:dict]){
                job = [AHLaunchJob jobFromDictionary:dict];
            }
        }else{
            job = [AHLaunchJob jobFromDictionary:dict];
        }
        if(job)
            job.domain = domain;
            [jobs addObject:job];
    }
    return [NSArray arrayWithArray:jobs];
}


#pragma mark - Error Codes
+(BOOL)errorWithCode:(NSInteger)code error:(NSError*__autoreleasing*)error{
    BOOL rc = code > 0?NO:YES;
    NSString * msg = errorMsgFromCode(code);
    NSError *err = [NSError errorWithDomain:@"com.eeaapps.launchctl" code:code userInfo:@{NSLocalizedDescriptionKey:msg}];
    if(error)
        *error = err;
    else
        NSLog(@"Error: %@",msg);
    
    return rc;
}

+(BOOL)errorWithCFError:(CFErrorRef)cfError code:(int)code error:(NSError*__autoreleasing*)error{
    BOOL rc = code > 0?NO:YES;
    
    NSError *err = CFBridgingRelease(cfError);

    if(error)
        *error = err;
    else
        NSLog(@"Error: %@",err.localizedDescription);
    
    return rc;
}

@end



#pragma mark - Utility Functions

static BOOL jobIsRunning(NSString* label, AHLaunchDomain domain){
    NSDictionary* dict =  AHJobCopyDictionary(domain, label);
    return dict ? YES:NO;
}

static BOOL jobExists(NSString* label, AHLaunchDomain domain){
    CFUserNotificationRef authNotification;
    CFOptionFlags         responseFlags;
    SInt32                cfError;
    NSString              *alertHeader;
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:launchFile(label, domain)];
    if(fileExists || jobIsRunning(label, domain)){
        alertHeader = [NSString stringWithFormat:@"A job with the same label exists in this domain, would you like to overwrite?"];
        
        CFOptionFlags flags = kCFUserNotificationPlainAlertLevel|
                                CFUserNotificationSecureTextField(1);
        
        NSDictionary *panelDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   alertHeader,kCFUserNotificationAlertHeaderKey,
                                   @"Cancel",kCFUserNotificationAlternateButtonTitleKey,
                                   @"",kCFUserNotificationAlertMessageKey,nil];
        
        authNotification = CFUserNotificationCreate(kCFAllocatorDefault,0,flags,&cfError,(__bridge CFDictionaryRef)panelDict);
        
        cfError = CFUserNotificationReceiveResponse(authNotification,0,&responseFlags);
        
        if (cfError){
            CFRelease(authNotification);
            return YES;
        }
        int button = responseFlags & 0x1;

        if (button == kCFUserNotificationAlternateResponse) {
            CFRelease(authNotification);
            return YES;
        }
        CFRelease(authNotification);
        return NO;
    }else{
        return NO;
    }
}

static NSString * errorMsgFromCode(NSInteger code){
    NSString * msg;
    switch (code) {
        case kAHErrorJobNotLoaded:msg = @"Job not loaded";
            break;
        case kAHErrorFileNotFound: msg = @"we could not find the specified launchd.plist to load the job";
            break;
        case kAHErrorCouldNotLoadJob: msg = @"Could not load job";
            break;
        case kAHErrorJobAlreayExists: msg = @"The specified job alreay exists";
            break;
        case kAHErrorJobAlreayLoaded: msg = @"The specified job is already loaded";
            break;
        case kAHErrorJobCouldNotReload: msg = @"The specified job is already loaded";
            break;
        case kAHErrorJobLabelNotValid: msg = @"The label is not valid. please format as a unique reverse domain";
            break;
        case kAHErrorCouldNotUnloadJob: msg = @"Could not unload job";
            break;
        case kAHErrorMultipleJobsMatching: msg = @"More than one job matched that description";
            break;
        case kAHErrorCouldNotWriteFile: msg = @"There were problem writing to the file";
            break;
        case kAHErrorInsufficentPriviledges: msg = @"There were problem writing to the file";
            break;
        case kAHErrorJobMissingRequiredKeys: msg = @"The Submitted Job was missing some required keys";
            break;
        case kAHErrorExecutingAsIncorrectUser: msg = @"Could not set the Job to run in the proper context";
            break;
        case kAHErrorProgramNotExecutable: msg = @"The path specified doesn’t appear to be executable.";
            break;
        default:msg = @"unknown problem occured";
            break;
    }
    return msg;
}

static NSString * launchFileDirectory(AHLaunchDomain domain){
    NSString* type = @"";
    NSString* fallback = [NSString stringWithFormat:@"%@/Library/LaunchAgents/",NSHomeDirectory()];
    switch(domain){
        case kAHGlobalLaunchAgent:type = @"/Library/LaunchAgents/";
            break;
        case kAHGlobalLaunchDaemon:type = @"/Library/LaunchDaemons/";
            break;
        case kAHSystemLaunchAgent:type = @"/System/Library/LaunchAgents/";
            break;
        case kAHSystemLaunchDaemon:type = @"/System/Library/LaunchDaemons/";
            break;
        case kAHUserLaunchAgent:type = fallback;
            break;
        default:type = fallback;
            break;
    }
    return type;
}

static NSString * launchFile(NSString* label, AHLaunchDomain domain){
    NSString* file;
    if(!domain || !label)return nil;
    file = [NSString stringWithFormat:@"%@/%@.plist",launchFileDirectory(domain),label];
    return file;
}


static BOOL setToConsoleUser (){
    uid_t effectiveUid;
    int results;
    
    CFBridgingRelease(SCDynamicStoreCopyConsoleUser(NULL, &effectiveUid, NULL));
    results = seteuid(effectiveUid);
    
    if( results != 0)
        return NO;
    else
        return YES;
}

static BOOL resetToOriginalUser(uid_t uid){
    int results;
    results = seteuid(uid);
    if( results != 0)
        return NO;
    else
        return YES;
}

