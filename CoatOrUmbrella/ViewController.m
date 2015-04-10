//
//  ViewController.m
//  CoatOrUmbrella
//
//  Created by Mike Bradford on 4/6/15.
//  Copyright (c) 2015 47Primes. All rights reserved.
//

#import "ViewController.h"
#import "CitySearchResultsController.h"
#import "Meteorologist.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController () <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>

@property (nonatomic) UISearchController *searchController;
@property (nonatomic) CitySearchResultsController *searchResultsController;
@property NSDictionary *cityDictionary;
@property NSArray *searchResults;
@property Meteorologist *m;
@property CLLocationManager *locationManager;

@end

@implementation ViewController

- (void)viewDidLoad
{
    self.title = @"Do I Need A Coat Or Umbrella Today?";
    
    [super viewDidLoad];
    [self buildSearchController];
    [self loadCityDictionary];
    
    _searchResults = [NSArray array];
    _m = [[Meteorologist alloc] init];
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    if ([CLLocationManager locationServicesEnabled]) {
        [_locationManager startMonitoringSignificantLocationChanges];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)loadCityDictionary
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"zip_codes" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSError *jsonError;
    _cityDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
}

- (void)buildSearchController
{
    _searchResultsController = [[CitySearchResultsController alloc] init];
    self.searchResultsController.tableView.delegate = self;
    self.searchResultsController.tableView.dataSource = self;
    
    _searchController = [[UISearchController alloc] initWithSearchResultsController:self.searchResultsController];
    self.searchController.searchBar.frame = self.view.frame;
    [self.searchController.searchBar addConstraints:self.headerView.constraints];
    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"Enter a city or zip code";
    [self.searchController.searchBar sizeToFit];
    [self.headerView addSubview:self.searchController.searchBar];
    
    self.definesPresentationContext = YES;
}

- (void)resetSearchBar
{
    self.searchController.active = NO;
    self.searchController.searchBar.text = self.m.city;
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self hideImages];
    self.searchController.searchBar.text = nil;
    self.forcastLabel.text = nil;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.m.city = searchBar.text;
    [self getWeatherData];
}


#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchText = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    [self citySearch:searchText];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResults.count;
}


#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cityCellIdentifier = @"CityCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cityCellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cityCellIdentifier];
    }
    cell.textLabel.text = [self.searchResults objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.m.city = [self.searchResults objectAtIndex:indexPath.row];
    [self getWeatherData];
}


#pragma mark - City search

- (void)citySearch:(NSString *)searchText
{
    searchText = [searchText lowercaseString];
    
    NSMutableOrderedSet *searchSet = [NSMutableOrderedSet orderedSet];
    
    for (NSString *key in self.cityDictionary)
    {
        NSString *value = [self.cityDictionary objectForKey:key];
        
        if ([key rangeOfString:searchText].location != NSNotFound || [[value lowercaseString] rangeOfString:searchText].location != NSNotFound)
        {
            [searchSet addObject:value];
        }
    }
    
    self.searchResults = [searchSet array];
    [self.searchResultsController.tableView reloadData];
}


#pragma mark - Weather API

- (void)getWeatherData
{
    [self resetSearchBar];
    [self.spinner startAnimating];
    [self.m checkWeather:^{
        [self handleWeatherResponse];
    }];
}

- (void)handleWeatherResponse
{
    [self.spinner stopAnimating];
    if (self.m.error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[self.m.error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    } else {
        self.searchController.active = NO;
        self.searchController.searchBar.text = self.m.city;
        self.forcastLabel.text = [self.m description];
        if ([self.m needsCoat]) {
            [self animateCoat];
        }
        if ([self.m needsUmbrella]) {
            [self animateUmbrella];
        }
    }
}

- (void)animateCoat
{
    [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.coatImage.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                     }];
}

- (void)animateUmbrella
{
    [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.umbrellaImage.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                     }];
}

- (void)hideImages
{
    self.coatImage.alpha = 0;
    self.umbrellaImage.alpha = 0;
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    NSDate *eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0) {
        self.m.latitude = location.coordinate.latitude;
        self.m.longitude = location.coordinate.longitude;
        [self getWeatherData];
    }
}

- (void)stopSignificantChangesUpdates
{
    [self.locationManager stopUpdatingLocation];
    self.locationManager = nil;
}

@end
