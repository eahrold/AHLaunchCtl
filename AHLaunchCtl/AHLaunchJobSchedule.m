//
//  NSDateComponents+AHLaunchCtlSchedule.m
//  AHLaunchCtl
//
//  Created by Eldon on 4/26/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import "AHLaunchJobSchedule.h"
NSInteger AHUndefinedSchedulComponent = NSUndefinedDateComponent;

@implementation AHLaunchJobSchedule

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key,
                                                        NSNumber *obj,
                                                        BOOL *stop) {
            if ([key.lowercaseString
                    isEqualToString:NSStringFromSelector(@selector(minute))]) {
                self.minute = obj.integerValue;
            } else if ([key.lowercaseString
                           isEqualToString:NSStringFromSelector(
                                               @selector(hour))]) {
                self.hour = obj.integerValue;
            } else if ([key.lowercaseString
                           isEqualToString:NSStringFromSelector(
                                               @selector(weekday))]) {
                self.weekday = obj.integerValue;
            } else if ([key.lowercaseString
                           isEqualToString:NSStringFromSelector(
                                               @selector(weekday))]) {
                self.day = obj.integerValue;
            } else if ([key.lowercaseString
                           isEqualToString:NSStringFromSelector(
                                               @selector(month))]) {
                self.month = obj.integerValue;
            }
        }];
    }
    return self;
}

- (NSString *)description {
    return self.dictionary.description;
}

- (NSDictionary *)dictionary {
    NSMutableDictionary *dict =
        [[NSMutableDictionary alloc] initWithCapacity:5];

    if (self.minute != AHUndefinedSchedulComponent)
        dict[@"Minute"] = @(self.minute);

    if (self.hour != AHUndefinedSchedulComponent) dict[@"Hour"] = @(self.hour);

    if (self.day != AHUndefinedSchedulComponent) dict[@"Day"] = @(self.day);

    if (self.weekday != AHUndefinedSchedulComponent)
        dict[@"Weekday"] = @(self.weekday);

    if (self.month != AHUndefinedSchedulComponent)
        dict[@"Month"] = @(self.month);

    return [NSDictionary dictionaryWithDictionary:dict];
}

+ (instancetype)scheduleWithMinute:(NSInteger)minute
                              hour:(NSInteger)hour
                               day:(NSInteger)day
                           weekday:(NSInteger)weekday
                             month:(NSInteger)month {
    AHLaunchJobSchedule *components = [AHLaunchJobSchedule new];

    if (minute != AHUndefinedSchedulComponent) {
        components.minute = minute;
    }
    if (hour != AHUndefinedSchedulComponent) {
        components.hour = hour;
    }
    if (day != AHUndefinedSchedulComponent) {
        components.day = day;
    }
    if (weekday != AHUndefinedSchedulComponent) {
        components.weekday = weekday;
    }
    if (month != AHUndefinedSchedulComponent) {
        components.month = month;
    }
    return components;
}

+ (instancetype)dailyRunAtHour:(NSInteger)hour minute:(NSInteger)minute {
    return [self scheduleWithMinute:minute
                               hour:hour
                                day:AHUndefinedSchedulComponent
                            weekday:AHUndefinedSchedulComponent
                              month:AHUndefinedSchedulComponent];
}

+ (instancetype)weeklyRunOnWeekday:(NSInteger)weekday hour:(NSInteger)hour {
    return [self scheduleWithMinute:00
                               hour:hour
                                day:AHUndefinedSchedulComponent
                            weekday:weekday
                              month:AHUndefinedSchedulComponent];
}

+ (instancetype)monthlyRunOnDay:(NSInteger)day hour:(NSInteger)hour {
    return [self scheduleWithMinute:00
                               hour:hour
                                day:day
                            weekday:AHUndefinedSchedulComponent
                              month:AHUndefinedSchedulComponent];
}

@end
