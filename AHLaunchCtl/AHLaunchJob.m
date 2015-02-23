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

#import "AHServiceManagement.h"
#import <objc/runtime.h>

@interface AHLaunchJob ()<NSSecureCoding>
@property (strong, atomic, readwrite) NSMutableDictionary *internalDictionary;
@property (nonatomic, readwrite) AHLaunchDomain domain;     //
@property (nonatomic, readwrite) NSInteger LastExitStatus;  //
@property (nonatomic, readwrite) NSInteger PID;             //
@property (nonatomic, readwrite) BOOL isCurrentlyLoaded;    //
@end

#pragma mark - AHLaunchJob
@implementation AHLaunchJob {
    unsigned int _count;
}

- (void)dealloc {
    [self removeObservingOnAllProperties];
}

- (instancetype)init {
    if (self = [super init]) {
        [self startObservingOnAllProperties];
    }
    return self;
}

- (instancetype)initWithoutObservers {
    if (self = [super init]) {
        _count = 33;
        _internalDictionary =
            [[NSMutableDictionary alloc] initWithCapacity:_count];
    }
    return self;
}

#pragma mark - Secure Coding
- (id)initWithCoder:(NSCoder *)aDecoder {
    NSSet *SAND = [NSSet setWithObjects:[NSArray class],
                                        [NSDictionary class],
                                        [NSString class],
                                        [NSNumber class],
                                        nil];
    if (self = [super init]) {
        _internalDictionary = [aDecoder
            decodeObjectOfClasses:SAND
                           forKey:NSStringFromSelector(@selector(dictionary))];
        _Label = [aDecoder
            decodeObjectOfClass:[NSString class]
                         forKey:NSStringFromSelector(@selector(Label))];
        _Program = [aDecoder
            decodeObjectOfClass:[NSString class]
                         forKey:NSStringFromSelector(@selector(Program))];
        _ProgramArguments =
            [aDecoder decodeObjectOfClasses:SAND
                                     forKey:NSStringFromSelector(
                                                @selector(ProgramArguments))];
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aEncoder {
    [aEncoder encodeObject:_internalDictionary
                    forKey:NSStringFromSelector(@selector(dictionary))];
    [aEncoder encodeObject:_Label
                    forKey:NSStringFromSelector(@selector(Label))];
    [aEncoder encodeObject:_Program
                    forKey:NSStringFromSelector(@selector(Program))];
    [aEncoder encodeObject:_ProgramArguments
                    forKey:NSStringFromSelector(@selector(ProgramArguments))];
}

#pragma mark - Instance Methods
- (NSDictionary *)dictionary {
    return [NSDictionary dictionaryWithDictionary:_internalDictionary];
}

- (NSString *)executableVersion {
    NSString *helperVersion;
    if (_ProgramArguments.count) {
        NSURL *execURL =
            [NSURL fileURLWithPath:[self.ProgramArguments objectAtIndex:0]];
        NSDictionary *helperPlist = (NSDictionary *)CFBridgingRelease(
            CFBundleCopyInfoDictionaryForURL((__bridge CFURLRef)(execURL)));
        if (helperPlist) helperVersion = helperPlist[@"CFBundleVersion"];
    }
    return helperVersion;
};

- (NSSet *)ignoredProperties {
    NSSet *const ignoredProperties = [NSSet
        setWithArray:
            @[ @"PID", @"LastExitStatus", @"isCurrentlyLoaded", @"domain" ]];
    return ignoredProperties;
}

#pragma mark--- Observing ---
- (void)startObservingOnAllProperties {
    objc_property_t *properties = class_copyPropertyList([self class], &_count);
    for (int i = 0; i < _count; ++i) {
        const char *property = property_getName(properties[i]);
        NSString *keyPath = [NSString stringWithUTF8String:property];
        if (![[self ignoredProperties] member:keyPath]) {
            [self addObserver:self
                   forKeyPath:keyPath
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
        }
    }
    free(properties);
}
- (void)removeObservingOnAllProperties {
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for (int i = 0; i < count; ++i) {
        const char *property = property_getName(properties[i]);
        NSString *keyPath = [NSString stringWithUTF8String:property];
        @try {
            if (![[self ignoredProperties] member:keyPath]) {
                [self removeObserver:self forKeyPath:keyPath];
            }
        }
        @catch (NSException *exception) {
        }
    }
    free(properties);
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (!_internalDictionary) {
        _internalDictionary =
            [[NSMutableDictionary alloc] initWithCapacity:_count];
    }

    id new = change[@"new"];

    if ([keyPath isEqualToString:@"StartCalendarInterval"] ||
        [keyPath isEqualToString:@"StartCalendarIntervalArray"]) {
        return [self handleStartCalendarInterval:keyPath change:new];
    }

    objc_property_t property =
        class_getProperty([self class], keyPath.UTF8String);
    const char *p = property_getAttributes(property);

    if (p != NULL) {
        if (!strncmp("Tc", p, 2)) {
            [self writeBoolValueToDict:new forKey:keyPath];
        } else
            [self writeObjectValueToDict:new forKey:keyPath];
    }
}

- (void)handleStartCalendarInterval:(NSString *)key change:(id)change {
    if ([change isKindOfClass:[AHLaunchJobSchedule class]]) {
        [_internalDictionary setObject:[change dictionary]
                                forKey:@"StartCalendarInterval"];

    } else if ([change isKindOfClass:[NSArray class]]) {
        NSMutableArray *sci =
            [[NSMutableArray alloc] initWithCapacity:[change count]];
        for (AHLaunchJobSchedule *schedule in change) {
            [sci addObject:schedule.dictionary];
        }
        [_internalDictionary setObject:sci forKey:@"StartCalendarInterval"];
    }
}

#pragma mark--- Accessors ---
- (NSInteger)LastExitStatus {
    if (_LastExitStatus) {
        return _LastExitStatus;
    }
    id value = [self serviceManagementValueForKey:@"LastExitStatus"];
    if (!value || ![value isKindOfClass:[NSNumber class]]) {
        return -1;
    }
    return [value integerValue];
}

- (NSInteger)PID {
    if (_PID) {
        return _PID;
    }
    id value = [self serviceManagementValueForKey:@"PID"];
    if (!value || ![value isKindOfClass:[NSNumber class]]) {
        return -1;
    }
    return [value integerValue];
}

- (BOOL)isCurrentlyLoaded {
    id test = [self serviceManagementValueForKey:@"Label"];
    if (test) return YES;
    return NO;
}

- (NSString *)description {
    if (!_internalDictionary.count) {
        return @"No Job Set";
    } else {
        NSInteger pid = self.PID;
        NSString *pidStr;
        if (pid == -1) {
            pidStr = @"--";
        } else {
            pidStr = [NSString stringWithFormat:@"%ld", pid];
        }
        NSInteger lastExitStatus = self.LastExitStatus;
        NSString *lastExitString;
        if (lastExitStatus == -1) {
            lastExitString = @"--";
        } else {
            lastExitString = @(lastExitStatus).stringValue;
        }
        NSString *loaded = self.isCurrentlyLoaded ? @"YES" : @"NO";

        NSString *format = [NSString
            stringWithFormat:@"Is Loaded:%@\tLastExit:%@\tPID:%@\tLabel:%@",
                             loaded,
                             lastExitString,
                             pidStr,
                             self.Label];
        return format;
    }
}

#pragma mark--- Private Methods ---
- (id)serviceManagementValueForKey:(NSString *)key {
    if (self.Label && self.domain != 0) {
        NSDictionary *dict = AHJobCopyDictionary(self.domain, self.Label);
        return [dict objectForKey:key];
    } else {
        return nil;
    }
}

- (void)writeBoolValueToDict:(id)value forKey:(NSString *)keyPath {
    if ([value isEqual:@YES]) {
        [_internalDictionary setValue:[NSNumber numberWithBool:(BOOL)value]
                               forKey:keyPath];
    } else {
        [_internalDictionary removeObjectForKey:keyPath];
    }
}

- (void)writeObjectValueToDict:(id)value forKey:(NSString *)keyPath {
    NSString *stringValue;
    if ([value isKindOfClass:[NSString class]]) stringValue = value;
    if ([value isKindOfClass:[NSNull class]] ||
        [stringValue isEqualToString:@""]) {
        [_internalDictionary removeObjectForKey:keyPath];
    } else {
        [_internalDictionary setValue:value forKey:keyPath];
    }
}

#pragma mark - Class Methods
+ (AHLaunchJob *)jobFromDictionary:(NSDictionary *)dict
                          inDomain:(AHLaunchDomain)domain {
    assert(dict != nil);
    AHLaunchJob *job = [[AHLaunchJob alloc] initWithoutObservers];
    job.domain = domain;

    for (id key in dict) {
        if ([key isKindOfClass:[NSString class]]) {
            @try {
                [job setValue:[dict valueForKey:key] forKey:key];
            }
            @catch (NSException *exception) {
                NSLog(@"Exception Raised: %@", exception);
            }
            [job.internalDictionary setValue:[dict valueForKey:key] forKey:key];
        }
    }
    [job startObservingOnAllProperties];
    return job;
}

+ (AHLaunchJob *)jobFromFile:(NSString *)file {
    // Normalize the string //
    NSString *filePath = [file stringByExpandingTildeInPath];
    AHLaunchDomain domain = 0;

    if ([filePath hasPrefix:@"/Library/LaunchAgents"]) {
        domain = kAHGlobalLaunchAgent;
    } else if ([filePath hasPrefix:@"/Library/LaunchDaemons"]) {
        domain = kAHGlobalLaunchDaemon;
    } else if ([filePath hasPrefix:@"/System/Library/LaunchAgents"]) {
        domain = kAHSystemLaunchAgent;
    } else if ([filePath hasPrefix:@"/System/Library/LaunchDaemons"]) {
        domain = kAHSystemLaunchDaemon;
    } else if ([filePath hasPrefix:NSHomeDirectory()]) {
        domain = kAHUserLaunchAgent;
    }

    NSDictionary *dict;
    // Check the file returns a dict, and that the dictionary returned
    // has both a label and program arguments keys.
    if ((dict = [NSDictionary dictionaryWithContentsOfFile:file])&&
        dict[NSStringFromSelector(@selector(Label))] &&
        dict[NSStringFromSelector(@selector(ProgramArguments))])
    {
        return [self jobFromDictionary:dict inDomain:domain];
    };

    return nil;
}

@end
#pragma mark - Functions
