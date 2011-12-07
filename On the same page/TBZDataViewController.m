//
//  TBZDataViewController.m
//  On the same page
//
//  Created by Toby Harris on 19/10/2011.
//  Copyright (c) 2011 Toby Harris. All rights reserved.
//
//  Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
//

#import "TBZDataViewController.h"

@implementation TBZDataViewController

@synthesize dataImageView = _dataImageView;
@synthesize dataObject = _dataObject;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.dataImageView.image = self.dataObject;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end
