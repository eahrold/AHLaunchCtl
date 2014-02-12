//  AHLaunchCtlHelper.m
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




#import "AHLaunchCtlHelper.h"
#import "AHAuthorizedLaunchCtl.h"

#pragma mark - AHLaunchCtl Extensioin;
@interface AHLaunchCtl ()
-(BOOL)writeJobToFile:(AHLaunchJob*)job inDomain:(AHlaunchDomain)domain error:(NSError**)error;
-(BOOL)removeJobFileWithLabel:(NSString*)label domain:(AHlaunchDomain)domain error:(NSError**)error;
@end

#pragma mark - AHLaunchCtlListener

@implementation AHLaunchCtlXPCListener{
@private
    __weak NSXPCConnection * _timerConnection;
    __strong AHAuthorizer *_timer;
    BOOL _authorizedForSession;
}

-(instancetype)initConnection{
    self = [super initWithMachServiceName:kAHLaunchCtlHelperName];
    if(self){
        self.delegate = self;
        [self resume];
    }
    return self;
}

-(void)addJob:(AHLaunchJob *)job toDomain:(AHlaunchDomain)domain authData:(NSData*)authData reply:(void (^)(NSError *))reply{
    NSError *error;
    AHLaunchCtl *controller = [AHLaunchCtl new];
    job = [AHLaunchJob jobFromDictionary:job.dictionary];
    
    if(!_authorizedForSession)
        error = [AHAuthorizer checkAuthorization:authData command:_cmd];
    
    if(!error)
        [controller writeJobToFile:job inDomain:domain error:&error];
    
    if(domain >= kAHSystemLaunchAgent && !error){
        [controller load:job inDomain:domain error:&error];
    }
    
    reply(error);
}

-(void)removeJob:(NSString *)label fromDomain:(AHlaunchDomain)domain authData:(NSData*)authData reply:(void (^)(NSError *))reply{
    AHLaunchCtl *controller = [AHLaunchCtl new];
    NSError *error;
    
    if(!_authorizedForSession)
        error = [AHAuthorizer checkAuthorization:authData command:_cmd];
    
    if(!error)
        [controller removeJobFileWithLabel:label domain:domain error:&error];
    
    if(domain >= kAHSystemLaunchAgent){
        [controller unload:label inDomain:domain error:&error];
    }
    
    reply(error);
}

-(void)authorizeSessionFor:(NSInteger)seconds authData:(NSData *)authData reply:(void (^)(NSError *error))reply{
    NSError *error;
    _authorizedForSession = NO;
    
    [_timer stopTimer];
    
    error = [AHAuthorizer checkAuthorization:authData command:_cmd];
    if(error){
        reply(error);
        return;
    }
    
    _authorizedForSession = YES;
    _timerConnection = _connection;
    
    if(!_timer)
        _timer = [[AHAuthorizer alloc]init];
    
    NSOperationQueue *timerQueue = [NSOperationQueue new];
    [timerQueue addOperationWithBlock:^{
        [_timer countDownFrom:seconds timeRemaining:^(NSInteger timer) {
            if(timer >= 0 ){
                [[_timerConnection remoteObjectProxy]countdown:timer];
            }else{
                _authorizedForSession = NO;
                [_timerConnection invalidate];
                _timerConnection = nil;
            }
        }];
    }];
    reply(error);
}

-(void)deAuthorizeSession:(void (^)(NSError *))reply{
    NSError *error;
    _authorizedForSession = NO;
    if(_timer)
        [_timer stopTimer];
    
    reply(error);
}

-(void)uninstallHelper:(NSString *)label authData:(NSData *)authData reply:(void (^)(NSError *))reply{
    NSError* error;
    error = [AHAuthorizer checkAuthorization:authData command:_cmd];
    if(!error){
        NSString *helperTool = [NSString stringWithFormat:@"/Library/PrivilegedHelperTools/%@",label];
        [[NSFileManager defaultManager] removeItemAtPath:helperTool error:&error];
        [[AHLaunchCtl sharedControler] remove:label fromDomain:kAHGlobalLaunchDaemon error:&error];
    }
    reply(error);
}

-(void)quitHelper{
    self.helperToolShouldQuit = YES;
}



#pragma mark NSXPC Delegate
//----------------------------------------
// Set up the one method of NSXPClistener
//----------------------------------------
- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AHLaunchCtlHelper)];
    newConnection.exportedObject = self;
    
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AHLaunchCtlProgress)];
    self.connection = newConnection;
    [newConnection resume];
    return YES;
}

#pragma mark  Listener Authorization



@end