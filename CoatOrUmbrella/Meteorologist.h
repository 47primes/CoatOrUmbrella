//
//  Meteorologist.h
//  CoatOrUmbrella
//
//  Created by Mike Bradford on 4/9/15.
//  Copyright (c) 2015 47Primes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Meteorologist : NSObject

@property NSString *city;
@property (readonly) NSError *error;

- (id) initWithCity:(NSString *)city;
- (NSString *)description;
- (void)checkWeather:(void(^)(void))callback;
- (BOOL)needsCoat;
- (BOOL)needsUmbrella;

@end
