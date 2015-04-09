//
//  ViewController.m
//  CoatOrUmbrella
//
//  Created by Mike Bradford on 4/6/15.
//  Copyright (c) 2015 47Primes. All rights reserved.
//

#import "ViewController.h"
#import "CitySearchResultsController.h"
#import "AFHTTPRequestOperationManager.h"

@interface ViewController () <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UISearchController *searchController;
@property (nonatomic) CitySearchResultsController *searchResultsController;
@property NSDictionary *cities;
@property NSArray *searchResults;

@end

@implementation ViewController

- (void)viewDidLoad
{
    self.title = @"Do I Need A Coat Or Umbrella Today?";
    
    [super viewDidLoad];
    [self buildSearchController];
    [self loadCities];
    
    _searchResults = [NSArray array];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)loadCities
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"zip_codes" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSError *jsonError;
    self.cities = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
}

- (void)buildSearchController
{
    _searchResultsController = [[CitySearchResultsController alloc] init];
    self.searchResultsController.tableView.delegate = self;
    self.searchResultsController.tableView.dataSource = self;
    
    _searchController = [[UISearchController alloc] initWithSearchResultsController:self.searchResultsController];
    self.searchController.searchBar.frame = CGRectMake(0, 0, self.view.frame.size.width, 44);
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


#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self.searchController.searchBar.text = nil;
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
    NSString *city = [self.searchResults objectAtIndex:indexPath.row];
    self.searchController.active = NO;
    self.searchController.searchBar.text = city;
    [self getWeatherData];
}


#pragma mark - City search

- (void)citySearch:(NSString *)searchText
{
    searchText = [searchText lowercaseString];
    
    NSMutableOrderedSet *searchSet = [NSMutableOrderedSet orderedSet];
    
    for (NSString *key in self.cities)
    {
        NSString *value = [self.cities objectForKey:key];
        
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
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:@"http://api.openweathermap.org/data/2.5/find?q=Austin,TX&units=imperial" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
