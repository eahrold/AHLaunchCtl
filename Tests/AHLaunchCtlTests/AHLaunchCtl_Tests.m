//
//  AHLaunchCtl_Tests.m
//  AHLaunchCtl Tests
//
//  Created by Eldon on 10/16/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
@import AHLaunchCtl;
 
#import <ServiceManagement/ServiceManagement.h>

@interface AHLaunchCtl_Tests : XCTestCase

@end

@implementation AHLaunchCtl_Tests {
    AHLaunchDomain _domain;
    AHLaunchJob *_job;
    AHLaunchCtl *_controller;
}

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each
    // test method in the class.
    [super setUp];

    _domain = kAHUserLaunchAgent;
    _controller = [AHLaunchCtl new];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of
    // each
    // test method in the class.
    [super tearDown];
}

#pragma mark - Default Test
- (void)testAllUserLaunchAgent {
    [self testAdd];
    [self testGetJob];
    [self testUnload];
    [self testLoad];
    [self testGetJob];
    [self testRestartJob];
    [self testRemoveJob];
    [self testStartCalendarInterval];
}

#pragma mark - Privileged tests
- (void)testAllAsGlobalLaunchDaemon {
    _domain = kAHGlobalLaunchDaemon;
    [self testAllUserLaunchAgent];
}

- (void)testAllAsGlobalLaunchAgent {
    _domain = kAHGlobalLaunchAgent;
    [self testAllUserLaunchAgent];
}

- (void)testKeepAliveGui {
    _job = [self guiJob];
    _job.KeepAlive = @(YES);

    _domain = kAHUserLaunchAgent;
    [self testLoad];
    [self testUnload];
}

- (void)testCreateJobFromDict {
    _job = [AHLaunchJob jobFromDictionary:@{
        @"Label" : @"com.me",
        @"ProgramArguments" : @[ @"/bin/echo", @"hello world!" ],
        @"SD" : @"gramps"
    } inDomain:kAHUserLaunchAgent];

    printf("%s", _job.dictionary.description.UTF8String);

    XCTAssertTrue(_job.dictionary[@"Label"], @"Job was not created");
    XCTAssertFalse(_job.dictionary[@"SD"], @"Job was not created");
}

- (void)testAuthorizedController {
    if ([_controller authorize]) {
        [self testAllAsGlobalLaunchDaemon];
    }
    [_controller deauthorize];
}

- (void)testAddSchedule {
    _job = [self echoJob];
    _job.StartCalendarInterval =
        [AHLaunchJobSchedule dailyRunAtHour:1 minute:10];

    [self testAdd];
}

#pragma mark - Tests
- (void)testAdd {
    NSError *error;
    if (!_job) {
        _job = [self echoJob];
    }

    BOOL success = [_controller add:_job toDomain:_domain error:&error];

    NSLog(@"%@", _job);
    XCTAssertTrue(success, @"Error %@", error);

    success = [self verifyWithSM];
    XCTAssertTrue(success,
                  @"Could not verify job was loaded using service management.");
}

- (void)testGetJob {
    if (!_job) {
        _job = [self echoJob];
    }

    AHLaunchJob *job =
        [AHLaunchCtl runningJobWithLabel:_job.Label inDomain:_domain];

    NSLog(@"%@", job);
    BOOL success = (job && job.Label && job.ProgramArguments);
    XCTAssertTrue(success, @"Could not get job %@", job);

    success = jobIsRunning(job.Label, _domain);
    XCTAssertTrue(success, @"Could not get job %@", job);

    success = [self verifyWithSM];
    XCTAssertTrue(success,
                  @"Could not verify job was loaded using service management.");
}

- (void)testUnload {
    BOOL initialFileCheck =
        [[NSFileManager defaultManager] fileExistsAtPath:[self jobFile]];

    NSError *error;
    if (!_job) {
        _job = [self echoJob];
    }

    BOOL success =
        [_controller unload:_job.Label inDomain:_domain error:&error];

    XCTAssertTrue(success, @"Error %@", error);

    if (initialFileCheck) {
        BOOL check2 =
            [[NSFileManager defaultManager] fileExistsAtPath:[self jobFile]];
        XCTAssertTrue(
            check2,
            @"Unloading removed the agent file, but shouldn't have!!!.");
    }

    success = [self verifyWithSM];
    XCTAssertFalse(
        success, @"Could not verify job was removed using service management.");
}

- (void)testLoad {
    NSError *error;
    if (!_job) {
        _job = [self echoJob];
    }

    BOOL success = [_controller load:_job inDomain:_domain error:&error];
    if (error.code != kAHErrorUserCanceledAuthorization) {
        XCTAssertTrue(success, @"Error %@", error);

        success = [self verifyWithSM];
        XCTAssertTrue(success, @"Could not verify job was loaded using service management.");
    }

}

- (void)testRestartJob {
    NSError *error;

    if (!_job) {
        _job = [self echoJob];
    }

    XCTAssertTrue(
        [_controller restart:_job.Label inDomain:_domain error:&error],
        @"Error: %@",
        error.localizedDescription);

    BOOL success = [self verifyWithSM];
    XCTAssertTrue(
        success,
        @"Could not verify job was reloaded using service management.");
}

- (void)testRemoveJob {
    NSError *error;
    if (!_job) {
        _job = [self echoJob];
    }

    XCTAssertTrue(
        [_controller remove:_job.Label fromDomain:_domain error:&error],
        @"Error: %@",
        error.localizedDescription);

    BOOL check2 =
        [[NSFileManager defaultManager] fileExistsAtPath:[self jobFile]];
    XCTAssertFalse(check2,
                   @"Did not remove the launch job file during user test.");

    BOOL success = [self verifyWithSM];
    XCTAssertFalse(
        success, @"Could not verify job was loaded using service management.");
}

- (void)testStartCalendarInterval {
    AHLaunchJob *job = [[AHLaunchJob alloc] init];
    NSError *error = nil;
    job.ProgramArguments = @[ @"/bin/echo", @"hello world!" ];
    job.Label = @"com.eeaapps.ahlaunchctl.check.schedule";

    AHLaunchJobSchedule *schedule =
        [AHLaunchJobSchedule dailyRunAtHour:1 minute:00];
    job.StartCalendarInterval = schedule;

    [[AHLaunchCtl sharedController] load:job
                                inDomain:kAHUserLaunchAgent
                                   error:&error];

    XCTAssertNil(error, @"%@", error);

    XCTAssertEqualObjects(schedule,
                          job.StartCalendarInterval,
                          @"Thsese should be equal %@ and %@",
                          schedule,
                          job.StartCalendarInterval);

    error = nil;
    [[AHLaunchCtl sharedController] unload:job.Label
                                  inDomain:kAHUserLaunchAgent
                                     error:&error];
    XCTAssertNil(error, @"%@", error);

    NSLog(@"%@", job.dictionary);
    NSLog(@"Dictionary Description: %@", job.StartCalendarInterval);
}
- (void)testCustomJobKeys {
    NSError *error;
    _job = [self echoJob];

    NSMutableDictionary *dict = [[_job dictionary] mutableCopy];
    [dict setValue:@{
        @"one" : @"first",
        @"two" : @"second"
    } forKey:@"cccDict"];

    AHLaunchJob *badJob =
        [AHLaunchJob jobFromDictionary:dict inDomain:kAHUserLaunchAgent];

    XCTAssertTrue([[AHLaunchCtl sharedController] load:badJob
                                              inDomain:kAHUserLaunchAgent
                                                 error:&error],
                  @"%@",
                  error);
    ;

    [[AHLaunchCtl sharedController] unload:badJob.Label
                                  inDomain:kAHUserLaunchAgent
                                     error:nil];
}

#pragma mark - Setup Helpers
- (AHLaunchJob *)echoJob {
    _job = [AHLaunchJob new];
    _job.Label = @"com.eeaapps.echo.helloworld";
    _job.ProgramArguments = @[ @"/bin/echo", @"hello world" ];
    _job.StandardOutPath = @"/tmp/hello.txt";
    _job.RunAtLoad = YES;
    return _job;
}

- (AHLaunchJob *)guiJob {
    _job = [AHLaunchJob new];
    _job.Label = @"com.eeaapps.echo.open.preview";
    _job.ProgramArguments =
        @[ @"/Applications/Preview.app/Contents/MacOS/Preview" ];
    _job.RunAtLoad = YES;
    return _job;
}

- (NSString *)jobFile {
    NSString *path = nil;
    switch (_domain) {
        case kAHUserLaunchAgent:
            path = kAHUserLaunchAgentTildeDirectory.stringByExpandingTildeInPath;
            break;
        case kAHGlobalLaunchAgent:
            path = kAHGlobalLaunchAgentDirectory;
            break;
        case kAHSystemLaunchAgent:
            path = kAHSystemLaunchAgentDirectory;
            break;
        case kAHGlobalLaunchDaemon:
            path = kAHGlobalLaunchDaemonDirectory;
            break;
        case kAHSystemLaunchDaemon:
            path = kAHSystemLaunchDaemonDirectory;
            break;
        default:
            break;
    }

    NSString *jobFile =
        [path stringByAppendingPathComponent:
                  [_job.Label stringByAppendingPathExtension:@"plist"]];
    return jobFile;
}

- (BOOL)verifyWithSM {
    CFStringRef domainStr = NULL;
    if (_domain > kAHGlobalLaunchAgent) {
        domainStr = kSMDomainSystemLaunchd;
    } else {
        domainStr = kSMDomainUserLaunchd;
    }

    BOOL success = NO;

    NSDictionary *dict = CFBridgingRelease(
        SMJobCopyDictionary(domainStr, (__bridge CFStringRef)(_job.Label)));

    success = (dict != nil);

    if (domainStr) CFRelease(domainStr);

    return success;
}

@end
