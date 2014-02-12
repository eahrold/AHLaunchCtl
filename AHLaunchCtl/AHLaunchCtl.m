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
#import "AHLaunchJob.h"
#import "AHAuthorizedLaunchCtl.h"

#import <ServiceManagement/ServiceManagement.h>
#import <SystemConfiguration/SystemConfiguration.h>

NSString* const kAHLaunchCtlHelperName = @"com.eeaapps.launchctl.helper";

static NSString * errorMsgFromCode(NSInteger code);
static NSString * launchFileDirectory(AHlaunchDomain domain);
static NSString * launchFile(NSString* label, AHlaunchDomain domain);
//static AuthorizationFlags defaultFlags();
static const CFStringRef SMDomain(AHlaunchDomain domain);
//static BOOL authorizeSystemDaemon(NSString * prompt,AuthorizationRef* authRef);
static BOOL jobIsRunning(NSString* label, AHlaunchDomain domain);
static BOOL jobExists(NSString* label, AHlaunchDomain domain);

enum LaunchControlErrorCodes
{
    kAHErrorJobNotLoaded       = 1001,
    kAHErrorJobLabelNotValid,
    kAHErrorJobAlreayExists,
    kAHErrorFileNotFound,
    kAHErrorCouldNotWriteFile,
    kAHErrorCouldNotLoadJob,
    kAHErrorCouldNotUnloadJob,
    kAHErrorMultipleJobsMatching,
    kAHErrorInsufficentPriviledges,
    kAHErrorMissingJobKeys,
    kAHErrorCouldNotSetUid,
    kAHErrorCouldNotResetUid,
    kAHErrorProgramNotExecutable,
};

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

#pragma mark - Add Remove Jobs
-(void)add:(AHLaunchJob*)job toDomain:(AHlaunchDomain)domain reply:(void (^)(NSError* error))reply{
    NSError* error;
    
    if(jobExists(job.Label,domain)){
        [[self class]errorWithCode:kAHErrorJobAlreayExists error:&error];
        reply(error);
        return;
    }
       
    if(domain > kAHUserLaunchAgent){
        [AHAuthorizedLaunchCtl addJob:job toDomain:domain reply:^(NSError *error) {
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

-(void)remove:(NSString*)label fromDomain:(AHlaunchDomain)domain reply:(void (^)(NSError* error))reply{
    if(domain > kAHUserLaunchAgent){
        [AHAuthorizedLaunchCtl removeJob:label fromDomain:domain reply:^(NSError *error) {
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

-(BOOL)add:(AHLaunchJob*)job toDomain:(AHlaunchDomain)domain error:(NSError *__autoreleasing *)error{
    if(domain > kAHUserLaunchAgent){
        job = [AHLaunchJob jobFromDictionary:job.dictionary];
    }
    
    if(!job.Label){
        return [[self class] errorWithCode:kAHErrorMissingJobKeys error:error];
    }
    
    if([self writeJobToFile:job inDomain:domain error:error]){
        return [self load:job inDomain:domain error:error];
    }
    return NO;
}

-(BOOL)remove:(NSString*)label fromDomain:(AHlaunchDomain)domain error:(NSError *__autoreleasing *)error{
    [self unload:label inDomain:domain error:error];
    return [self removeJobFileWithLabel:label domain:domain error:error];
}

#pragma mark - Load / Unload Jobs
-(BOOL)load:(AHLaunchJob*)job inDomain:(AHlaunchDomain)domain error:(NSError *__autoreleasing *)error{
    BOOL rc;
    CFErrorRef cfError;
    int result;
    uid_t effectiveUid;
    uid_t originalUid;
    uid_t currentUid;

    originalUid = getuid();
    CFBridgingRelease(SCDynamicStoreCopyConsoleUser(NULL, &effectiveUid, NULL));
    
    AuthorizationRef authRef = NULL;
    if(domain >= kAHSystemLaunchAgent)
        [AHAuthorizer authorizeSystemDaemon:@"Load Job?" authRef:&authRef];

    if(domain < kAHSystemLaunchAgent){
        result = seteuid(effectiveUid);
        if (result != 0) {
            return [[self class]errorWithCode:kAHErrorCouldNotSetUid error:error];
        }
    }

    currentUid = geteuid();

    rc =  SMJobSubmit(SMDomain(domain),
                      (__bridge CFDictionaryRef)job.dictionary,
                      authRef,
                      &cfError);
    
    if(!rc){
        [[self class] errorWithCFError:cfError code:1 error:error];
    }
    
    seteuid(originalUid);
    [AHAuthorizer authoriztionFree:authRef];
    
    return rc;
}

-(BOOL)unload:(NSString*)label inDomain:(AHlaunchDomain)domain error:(NSError *__autoreleasing *)error{
    BOOL rc;
    int result;
    uid_t effectiveUid;
    uid_t originalUid;
    
    originalUid = getuid();
    CFBridgingRelease(SCDynamicStoreCopyConsoleUser(NULL, &effectiveUid, NULL));
    
    AuthorizationRef authRef = NULL;
    if(domain >= kAHSystemLaunchAgent)
        [AHAuthorizer authorizeSystemDaemon:@"Unoad Job?" authRef:&authRef];

    if(domain < kAHSystemLaunchAgent){
        result = seteuid(effectiveUid);
        if (result != errAuthorizationSuccess) {
            return [[self class]errorWithCode:kAHErrorCouldNotSetUid error:error];
        }
    }
    
    CFErrorRef cfError = NULL;
    rc =  SMJobRemove(SMDomain(domain), (__bridge CFStringRef)label, authRef, YES, &cfError);
    [AHAuthorizer authoriztionFree:authRef];
    
    if(!rc){
        [[self class] errorWithCFError:cfError code:1 error:error];
    }
    
    if(!effectiveUid == originalUid){
        result = seteuid(originalUid);
        if (!result == errAuthorizationSuccess) {
            [[self class] errorWithCode:kAHErrorCouldNotResetUid error:error];
        }
    }
    
    return rc;
}

-(BOOL)start:(NSString*)label inDomain:(AHlaunchDomain)domain error:(NSError*__autoreleasing*)error{
    AHLaunchJob* job = [[self class]jobFromFileNamed:label inDomain:domain];
    if(job){
        return [self load:job inDomain:domain error:error];
    }else{
        return [[self class] errorWithCode:kAHErrorCouldNotLoadJob error:error];
    }
}

-(BOOL)stop:(NSString*)label inDomain:(AHlaunchDomain)domain error:(NSError*__autoreleasing*)error{
    return [self unload:label inDomain:domain error:error];
}

-(BOOL)restart:(NSString*)label inDomain:(AHlaunchDomain)domain error:(NSError *__autoreleasing *)error{
    AHLaunchJob *job = [[self class]runningJobWithLabel:label inDomain:domain];
    if(job){
        if([self unload:job.Label inDomain:domain error:error]){
            return [self load:job inDomain:domain error:error];
        }else{
            return NO;
        }
    }else{
        return [[self class]errorWithCode:kAHErrorJobNotLoaded error:error];
    }
    
    return NO;
}

-(BOOL)shouldLoadJob:(BOOL)load shouldStick:(BOOL)wKey label:(NSString*)label domain:(AHlaunchDomain)domain error:(NSError *__autoreleasing*)error{
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

#pragma mark - Authorization
-(void)authorizeSessionFor:(NSInteger)seconds
                     error:(void (^)(NSError *error))error
             timeRemaining:(void (^)(NSInteger time))timeRemaining
{
    [AHAuthorizedLaunchCtl authorizeSessionFor:(NSInteger)seconds error:^(NSError *replyError) {
        error(replyError);
    }timeRemaining:^(NSInteger time) {
        timeRemaining(time);
    }];
}

-(void)deAuthorizeSession:(void (^)(NSError *))reply{
    [AHAuthorizedLaunchCtl deAuthorizeSession:^(NSError *error) {
        reply(error);
    }];
}

#pragma mark - File Writing
-(BOOL)writeJobToFile:(AHLaunchJob*)job inDomain:(AHlaunchDomain)domain error:(NSError*__autoreleasing*)error{
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

-(BOOL)removeJobFileWithLabel:(NSString*)label domain:(AHlaunchDomain)domain error:(NSError*__autoreleasing*)error{
    NSFileManager* fm = [NSFileManager new];
    NSString* file = launchFile(label, domain);
    if([fm fileExistsAtPath:file isDirectory:NO]){
        return [fm removeItemAtPath:file error:error];
    }else{
        return YES;
    }
}

#pragma mark - Convience Accessors;
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
    
    AHlaunchDomain domain = global ? kAHGlobalLaunchAgent:kAHUserLaunchAgent;
    return [controller load:job inDomain:domain error:error];
}

+(BOOL)scheduleJob:(NSString*)label program:(NSString*)program interval:(int)seconds domain:(AHlaunchDomain)domain error:(NSError**)error
{
    return [self scheduleJob:label program:program programArguments:nil interval:seconds domain:domain error:error];
}

+(BOOL)scheduleJob:(NSString*)label program:(NSString*)program programArguments:(NSArray*)programArguments interval:(int)seconds domain:(AHlaunchDomain)domain error:(NSError *__autoreleasing *)error
{
    AHLaunchCtl *controller = [AHLaunchCtl new];
    AHLaunchJob* job = [AHLaunchJob new];
    job.Label = label;
    job.Program = program;
    job.ProgramArguments = programArguments;
    job.RunAtLoad = YES;
    job.StartInterval = seconds;
    return [controller add:job toDomain:domain error:error];
}

+(BOOL)removeJob:(NSString*)label type:(AHlaunchDomain)domain error:(NSError*__autoreleasing*)error{
    AHLaunchCtl* controller = [AHLaunchCtl new];
    return [controller remove:label fromDomain:domain error:error];
}

+(BOOL)restartJobWithLabel:(NSString *)label domain:(AHlaunchDomain)domain{
    AHLaunchCtl* launchctl = [[AHLaunchCtl alloc]init];
    return [launchctl restart:label inDomain:domain error:nil];
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

+(AHLaunchJob *)jobFromFileNamed:(NSString *)label inDomain:(AHlaunchDomain)domain
{
    AHLaunchJob* job;
    NSFileManager  * fm         = [NSFileManager new];
    
    NSString * launchDirectory = launchFileDirectory(domain);
    NSArray  * launchFiles = [fm contentsOfDirectoryAtPath:launchDirectory
                                                         error:nil];
    
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH[c] %@",label];

    for(NSString * file in launchFiles){
        if([predicate evaluateWithObject:file]){
            NSString * filePath = [NSString stringWithFormat:@"%@/%@",launchDirectory,file];
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
            if(dict){
                 job = [AHLaunchJob jobFromDictionary:dict];
                break;
            }
        }
    }
    return job;
}

+(NSArray *)allJobsFromFilesMatching:(NSString*)match{
    NSMutableArray * jobs  = [[NSMutableArray alloc]init];
    
    [jobs addObject:[[self class] jobFromFileNamed:match inDomain:kAHSystemLaunchDaemon]];
    [jobs addObject:[[self class] jobFromFileNamed:match inDomain:kAHSystemLaunchAgent]];
    [jobs addObject:[[self class] jobFromFileNamed:match inDomain:kAHGlobalLaunchDaemon]];
    [jobs addObject:[[self class] jobFromFileNamed:match inDomain:kAHGlobalLaunchAgent]];
    [jobs addObject:[[self class] jobFromFileNamed:match inDomain:kAHUserLaunchAgent]];

    return [NSArray arrayWithArray:jobs];
}

+(NSArray*)allRunningJobsMatching:(NSString*)match{
    NSMutableArray * jobs  = [[NSMutableArray alloc]init];

    [jobs addObjectsFromArray:[[self class] runningJobMatching:match
                                               inDomain:kAHUserLaunchAgent]];
    [jobs addObjectsFromArray:[[self class] runningJobMatching:match
                                               inDomain:kAHGlobalLaunchDaemon]];
    
    return [NSArray arrayWithArray:jobs];
}

+(AHLaunchJob *)runningJobWithLabel:(NSString *)label inDomain:(AHlaunchDomain)domain{
    NSDictionary* dict =  (__bridge NSDictionary *)(SMJobCopyDictionary(SMDomain(domain),
                                                                        (__bridge CFStringRef)(label)));
    
    return [AHLaunchJob jobFromDictionary:dict];
}

+(NSArray*)runningJobMatching:(NSString*)match inDomain:(AHlaunchDomain)domain{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"SELF.Label CONTAINS[c] %@ OR SELF.Program CONTAINS[c] %@",match,match];
    return [self jobMatch:match domain:domain predicate:predicate];
}

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
    [AHAuthorizedLaunchCtl uninstallHelper:label reply:^(NSError *error) {
        reply(error);
    }];
}

+(NSArray*)jobMatch:(NSString*)match domain:(AHlaunchDomain)domain predicate:(NSPredicate*)predicate{
    NSArray* array = (__bridge NSArray *)(SMCopyAllJobDictionaries(SMDomain(domain)));
    if(!array.count)return nil;
    
    
    NSMutableArray *jobs = [[NSMutableArray alloc]initWithCapacity:array.count];
    for(NSDictionary* dict in array){
        if([predicate evaluateWithObject:dict]){
            [jobs addObject:[AHLaunchJob jobFromDictionary:dict]];
        }
    }
    
    return [NSArray arrayWithArray:jobs];
}

+(void)quitHelper{
    [AHAuthorizedLaunchCtl quitHelper];
}

#pragma mark - Error Codes
+(BOOL)errorWithCode:(NSInteger)code error:(NSError*__autoreleasing*)error{
    BOOL rc = code > 0?NO:YES;
    NSString * msg = errorMsgFromCode(code);
    NSError *err = [NSError errorWithDomain:@"com.eeaapps.objc.launchctl" code:code userInfo:@{NSLocalizedDescriptionKey:msg}];
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

+(BOOL)labelIsValid:(NSString *)label forDomain:(AHlaunchDomain)domain{
    
    if([label length] > 150 || [self jobFromFileNamed:label inDomain:domain])
        return NO;
    else
        return YES;
}

@end



#pragma mark - Utility Functions
static BOOL jobIsRunning(NSString* label, AHlaunchDomain domain){
    NSDictionary* dict =  (__bridge NSDictionary *)(SMJobCopyDictionary(SMDomain(domain),
                                                                        (__bridge CFStringRef)(label)));
    return dict ? YES:NO;
}

static BOOL jobExists(NSString* label, AHlaunchDomain domain){
    CFUserNotificationRef authNotification;
    CFOptionFlags         responseFlags;
    SInt32                cfError;
    NSString              *alertHeader;
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:launchFile(label, domain)];
    if(fileExists || jobIsRunning(label, domain)){
        alertHeader = [NSString stringWithFormat:@"Job Exists, would you like to overwright"];
        
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
        case kAHErrorFileNotFound: msg = @"Launchd.plist not found";
            break;
        case kAHErrorCouldNotLoadJob: msg = @"Could not load job";
            break;
        case kAHErrorJobAlreayExists: msg = @"The specified job alreay exists";
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
        case kAHErrorMissingJobKeys: msg = @"The Submitted Job was missing some required keys";
            break;
        case kAHErrorCouldNotSetUid: msg = @"Could not set the Job to run in the proper context";
            break;
        case kAHErrorCouldNotResetUid: msg = @"Could not return the tool to the proper user";
            break;
        case kAHErrorProgramNotExecutable: msg = @"The path specified doesn’t appear to be executable.";
            break;
            
        default:msg = @"unknown problem occured";
            break;
    }
    return msg;
}

static NSString * launchFileDirectory(AHlaunchDomain domain){
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

static NSString * launchFile(NSString* label, AHlaunchDomain domain){
    NSString* file;
    if(!domain || !label)return nil;
    file = [NSString stringWithFormat:@"%@/%@.plist",launchFileDirectory(domain),label];
    return file;
}

static const CFStringRef SMDomain(AHlaunchDomain domain){
    if(domain > kAHGlobalLaunchAgent){
        return kSMDomainSystemLaunchd;
    }else{
        return kSMDomainUserLaunchd;
    }
}


