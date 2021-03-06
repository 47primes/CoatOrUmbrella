//
//  ViewController.h
//  CoatOrUmbrella
//
//  Created by Mike Bradford on 4/6/15.
//  Copyright (c) 2015 47Primes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UISearchBarDelegate, UISearchControllerDelegate>

@property IBOutlet UILabel *forcastLabel;
@property IBOutlet UIImageView *coatImage;
@property IBOutlet UIImageView *umbrellaImage;
@property IBOutlet UIBarButtonItem *configButton;
@property IBOutlet UIView *headerView;
@property IBOutlet UIActivityIndicatorView *spinner;

@end

