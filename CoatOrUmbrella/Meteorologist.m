//
//  Meteorologist.m
//  CoatOrUmbrella
//
//  Created by Mike Bradford on 4/9/15.
//  Copyright (c) 2015 47Primes. All rights reserved.
//

#import "Meteorologist.h"
#import "AFHTTPRequestOperationManager.h"

@implementation Meteorologist {
    NSString *_rainDescription;
    float _highTemp;
    float _lowTemp;
}

- (id) initWithLatitude:(float)latitude andLongitude:(float)longitude
{
    if (self = [super init]) {
        _latitude = latitude;
        _longitude = longitude;
        return self;
    } else {
        return nil;
    }
}

- (NSString *)description
{
    NSString *message;
    if ([self needsCoat] && [self needsUmbrella]) {
        message = @"Yes, you need both.";
    } else if ([self needsCoat]) {
        message = @"Yes, you need a coat.";
    } else if ([self needsUmbrella]) {
        message = @"Yes, you need an umbrella.";
    } else {
        message = @"Neither.";
    }
    
    return [NSString stringWithFormat: @"%@ Low of %.02f °F. %@", message, _lowTemp, _rainDescription];
}

- (void)checkWeather:(void(^)(void))callback
{
    _error = nil;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:@"http://api.openweathermap.org/data/2.5/find" parameters:[self requestParameters] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *lists = [responseObject objectForKey:@"list"];
        if (lists.count > 0) {
            NSDictionary *list = [[responseObject objectForKey:@"list"] objectAtIndex:0];
            NSDictionary *weather = [[list objectForKey:@"weather"] objectAtIndex:0];
            
            _highTemp = [[[list objectForKey:@"main"] valueForKey:@"temp_max"] floatValue];
            _lowTemp = [[[list objectForKey:@"main"] valueForKey:@"temp_min"] floatValue];
            if (!_city) {
                _city = [list objectForKey:@"name"];
            }
            
            _rainDescription = [weather valueForKey:@"description"];
        } else {
            _error = [NSError errorWithDomain:@"Unable to find weather data" code:0 userInfo:nil];
        }
        callback();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        _error = error;
        callback();
    }];
}

- (NSDictionary *)requestParameters
{
    NSDictionary *parameters;
    if (self.city.length > 0) {
        parameters = @{@"q": self.city, @"units": @"imperial"};
    } else {
        parameters = @{@"lat": [NSNumber numberWithFloat:self.latitude], @"lon": [NSNumber numberWithFloat:self.longitude], @"units": @"imperial"};
    }
    return parameters;
}

- (BOOL)needsCoat
{
    return _lowTemp < 40;
}

- (BOOL)needsUmbrella
{
    return [[_rainDescription lowercaseString] rangeOfString:@"rain"].location != NSNotFound;
}

@end
