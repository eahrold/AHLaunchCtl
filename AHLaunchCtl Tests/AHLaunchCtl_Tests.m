//
//  AHLaunchCtl_Tests.m
//  AHLaunchCtl Tests
//
//  Created by Eldon on 10/16/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "AHLaunchCtl.h"
#import <ServiceManagement/ServiceManagement.h>

@interface AHLaunchCtl_Tests : XCTestCase

@end

@implementation AHLaunchCtl_Tests {
    AHLaunchDomain _domain;
    AHLaunchJob *_job;
}

- (void)setUp {
    [super setUp];
    _domain = kAHUserLaunchAgent;

    // Put setup code here. This method is called before the invocation of each
    // test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of
    // each
    // test method in the class.
    [super tearDown];
}

#pragma mark - Default Test
- (void)testAllStd {
    [self testAdd];
    [self testGetJob];
    [self testUnload];
    [self testLoad];
    [self testGetJob];
    [self testRestartJob];
    [self testRemoveJob];
}

#pragma mark - Priviledged tests
- (void)testAllAsGlobalLaunchDaemon {
    _domain = kAHGlobalLaunchDaemon;
    [self testAllStd];
}

- (void)testAllAsGlobalLaunchAgent {
    _domain = kAHGlobalLaunchAgent;
    [self testAllStd];
}

- (void)testGui {
    _job = [self guiJob];
    _job.KeepAlive = @(YES);

    _domain = kAHUserLaunchAgent;
    [self testLoad];
    [self testUnload];
}

#pragma mark - Tests
- (void)testAdd {
    NSError *error;
    if (!_job) {
        _job = [self echoJob];
    }

    BOOL success =
        [[AHLaunchCtl sharedController] add:_job toDomain:_domain error:&error];

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

    BOOL success = [[AHLaunchCtl sharedController] unload:_job.Label
                                                 inDomain:_domain
                                                    error:&error];

    XCTAssertTrue(success, @"Error %@", error);

    if (initialFileCheck) {
        BOOL check2 =
        [[NSFileManager defaultManager] fileExistsAtPath:[self jobFile]];
        XCTAssertTrue(check2,
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

    BOOL success = [[AHLaunchCtl sharedController] load:_job
                                               inDomain:_domain
                                                  error:&error];

    XCTAssertTrue(success, @"Error %@", error);

    success = [self verifyWithSM];
    XCTAssertTrue(success,
                  @"Could not verify job was loaded using service management.");
}

- (void)testRestartJob {
    NSError *error;

    if (!_job) {
        _job = [self echoJob];
    }

    XCTAssertTrue([[AHLaunchCtl sharedController] restart:_job.Label
                                                 inDomain:_domain
                                                    error:&error],
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

    XCTAssertTrue([[AHLaunchCtl sharedController] remove:_job.Label
                                              fromDomain:_domain
                                                   error:&error],
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
            path = [@"~/Library/LaunchAgents/" stringByExpandingTildeInPath];
            break;
        case kAHGlobalLaunchAgent:
            path = @"/Library/LaunchAgents/";
            break;
        case kAHSystemLaunchAgent:
            path = @"/System/Library/LaunchAgents/";
            break;
        case kAHGlobalLaunchDaemon:
            path = @"/Library/LaunchDaemons/";
            break;
        case kAHSystemLaunchDaemon:
            path = @"/System/Library/LaunchDaemons/";
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
