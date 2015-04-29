//
//  WatchViewController.m
//  Kamcord
//
//  Created by Andy Reyes on 4/19/15.
//  Copyright (c) 2015 Andy Reyes. All rights reserved.
//

#import "WatchViewController.h"
#import "KamcordVideo.h"
#import "WatchViewCell.h"
#import <MediaPlayer/MediaPlayer.h>


@interface WatchViewController()


@property (readonly) NSDictionary*     JSONData;
@property (readonly) NSArray*          videos;
@property MPMoviePlayerViewController* videoPlayer;

@property (strong, nonatomic) IBOutlet UITableView* watchTableView;


@end


@implementation WatchViewController


#pragma mark - Synthesize


@synthesize JSONData = _JSONData;
@synthesize videos = _videos;


#pragma mark - Constants


static NSString* kVidDataSrcStr                     = @"https://www.kamcord.com/app/v2/videos/feed/?feed_id=0";
static NSString* kResStr                            = @"response";
static NSString* kVidListStr                        = @"video_list";
static NSString* kVidURLStr                         = @"video_url";
static NSString* kVidTitleStr                       = @"title";
static NSString* kVidThumbStr                       = @"thumbnails";
static NSString* kVidRegularThumbStr                = @"REGULAR";
static NSString* kWatchViewCellIdentifier           = @"Watch View Cell";
static NSString* kNormalCellIdentifier              = @"Normal Cell";
static NSString* kThumbnailPlaceholderIdentifier    = @"Thumbnail Placeholder";

#define kCustomRowCount             7
#define kThumbnailCrossDissolveTime 0.5
#define kTableRowHeightiPhone       220
#define kTableRowHeightiPad         400
#define kTitleFontSizeiPhone        20
#define kTitleFontSizeiPad          40
#define kRefreshFontSize            14.0

#define kStartColorHue      0.58
#define kStartColorSat      0.50
#define kStartColorBri      0.62
#define kStartColorAlpha    0.0

#define kEndColorHue        0.0
#define kEndColorSat        0.0
#define kEndColorBri        0.0
#define kEndColorAlpha      0.6


#pragma mark - JSON Parsing


- (NSDictionary*) JSONData
{
    // We obtain the JSON Data synchronously since we need it to populate all other UI
    
    @synchronized(self)
    {
        if (!_JSONData)
        {
            NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:kVidDataSrcStr]];
            NSURLResponse* response;
            NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
            NSDictionary* res = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            _JSONData = [[res objectForKey:kResStr] objectForKey:kVidListStr];
        }
        
        return _JSONData;
    }
}


- (NSArray*) videos
{
    // Parse out the JSON video data to create an array of KamcordVideo objects

    @synchronized(self)
    {
        if (!_videos)
        {
            NSMutableArray* temp = [[NSMutableArray alloc] init];
            
            for (id videoData in [self JSONData])
            {
                @autoreleasepool
                {
                    KamcordVideo* video = [[KamcordVideo alloc] init];
                    
                    video.title = [videoData objectForKey:kVidTitleStr];
                    video.videoURLString = [videoData objectForKey:kVidURLStr];
                    video.thumbnailURLString = [[videoData objectForKey:kVidThumbStr] objectForKey:kVidRegularThumbStr];
                    video.thumbnailImage = nil;  // We load thumbnail images asynchronously later
                    
                    [temp addObject:video];
                }
            }
            
            _videos = [[NSArray alloc] initWithArray:temp];
        }
        
        return _videos;
    }
}


#pragma mark - Data Refresh


- (void)deleteAllData
{
    _JSONData = nil;
    _videos = nil;
}


- (void)forceRefreshTable
{
    [self deleteAllData];
    [[self watchTableView] reloadData];
}


- (IBAction)refresh {
    
    [self.refreshControl beginRefreshing];
    
    self.refreshControl.attributedTitle = [self getRandomRefreshQuip];
    [self forceRefreshTable];
    
    [self.refreshControl endRefreshing];
}


- (NSAttributedString*)getRandomRefreshQuip
{
    // Just something fun...
    
    NSArray* refreshQuips = @[@"BOOM! HEADSHOT!", @"LEEEEROOOOY, JEEENKIIINS!",
                              @"FATALITY", @"THE CAKE IS A LIE", @"RESPAWNING...",
                              @"KAMCORD RULES!", @"ALL GLORY TO THE HYPNOTOAD",
                              @"POLYBIUS IS REAL", @"I'M A FORCE OF NATURE!",
                              @"HALF-LIFE 3 CONFIRMED!", @"FUS RO DAH!", @"QWOP",
                              @"PWNED!", @"BEHIND YOU! SLENDERMAN!", @"PLEASE UNDERSTAND...",
                              @"OBJECTION!", @"GOTTA GO FAST!", @"HADOUKEN!", @"CONTINUE?",
                              @"THE PRINCESS IS IN ANOTHER CASTLE", @"A WINNER IS YOU!",
                              @"ALL YOUR BASE ARE BELONG TO US", @"C-C-C-COMBO BREAKER!"];
    
    // Picks a string from the list at random
    NSMutableAttributedString* refreshQuip = [[NSMutableAttributedString alloc] initWithString:[refreshQuips objectAtIndex:arc4random_uniform((u_int32_t)refreshQuips.count)]];
    
    // It would be nice if the font matched the Storyboard's Refresh font
    UIFont* font = [UIFont systemFontOfSize:kRefreshFontSize];
    [refreshQuip addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, refreshQuip.length)];
    
    return refreshQuip;
}


#pragma mark - Asynchronous Image Loading Into Table Cells


- (void)downloadImageAsynchronouslyWithURL:(NSString*)urlString
                           completionBlock:(void (^)(BOOL succeeded, UIImage *image))completionBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if ( !error )
                               {
                                   UIImage* image = [[UIImage alloc] initWithData:data];
                                   completionBlock(YES, image);
                               }
                               else
                               {
                                   completionBlock(NO, nil);
                               }
                           }];
}


- (void)downloadVideoThumbnailAsynchronouslyForIndexPath:(NSIndexPath*)indexPath
{
    if ([[self videos] count] >= indexPath.row)
    {
        KamcordVideo* kamcordVideo = [[self videos] objectAtIndex:indexPath.row];
        
        [self downloadImageAsynchronouslyWithURL:kamcordVideo.thumbnailURLString
                                 completionBlock:^(BOOL succeeded, UIImage* thumbnail) {
                                     if (succeeded)
                                     {
                                         // Set the Kamcord Video's thumbnail
                                         kamcordVideo.thumbnailImage = thumbnail;
                                         
                                         // Only update the table cell if it is visible
                                         UITableViewCell* cell = [self.watchTableView cellForRowAtIndexPath:indexPath];
                                         
                                         if (cell)
                                         {
                                             // Animate so it looks nice
                                             [UIView transitionWithView:cell.imageView
                                                               duration:kThumbnailCrossDissolveTime
                                                                options:UIViewAnimationOptionTransitionCrossDissolve |
                                                                        UIViewAnimationOptionAllowUserInteraction
                                                             animations:^{
                                                                 
                                                                 if ([cell isKindOfClass:[WatchViewCell class]])
                                                                 {
                                                                     [(WatchViewCell*)cell mainImageView].image = thumbnail;
                                                                 }
                                                                 else
                                                                 {
                                                                     cell.imageView.image = thumbnail;
                                                                 }
                                                                 
                                                             } completion:nil];
                                         }
                                     }
                                 }];
        
    }
}


#pragma mark - UITableViewDelegate


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    CGFloat height = kTableRowHeightiPhone;
    
    switch (UIDevice.currentDevice.userInterfaceIdiom)
    {
        case UIUserInterfaceIdiomPad:
            height = kTableRowHeightiPad;
            break;
        case UIUserInterfaceIdiomPhone:
            height = kTableRowHeightiPhone;
        default:
            height = kTableRowHeightiPhone;
            break;
    }
    
    return height;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    // Display the video!
    
    KamcordVideo* kamcordVideo = [[self videos] objectAtIndex:indexPath.row];
    
    if (kamcordVideo.videoURLString)
    {
        self.videoPlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:kamcordVideo.videoURLString]];
        
        self.videoPlayer.moviePlayer.allowsAirPlay = YES;
        self.videoPlayer.moviePlayer.controlStyle = MPMovieControlStyleFullscreen;
        
        [self presentMoviePlayerViewControllerAnimated:self.videoPlayer];
    }
}


#pragma mark - UITableViewDataSource


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = [[self videos] count];
    
    // If there's no data yet,
    // at least attempt to fill the screen with rows
    if (count <= 0)
    {
        return kCustomRowCount;
    }
    
    return count;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    WatchViewCell *cell = [self.watchTableView dequeueReusableCellWithIdentifier:kWatchViewCellIdentifier forIndexPath:indexPath];
    
    NSUInteger nodeCount = [[self videos] count];
    
    if (nodeCount == 0 && indexPath.row == 0)
    {
        cell.title.text = @"Loading...";
    }
    else
    {
        // Only populate cells if there is data
        if (nodeCount > 0)
        {
            // Populate the WatchViewCell
            KamcordVideo* kamcordVideo = [[self videos] objectAtIndex:indexPath.row];
            
            cell.title.text = kamcordVideo.title;
            
            // Use cached thumbnail if we have it, otherwise download it asynchronously
            if (!kamcordVideo.thumbnailImage)
            {
                // Use a placeholder image while we wait for the real one to download
                cell.mainImageView.image = [UIImage imageNamed:kThumbnailPlaceholderIdentifier];
                
                [self downloadVideoThumbnailAsynchronouslyForIndexPath:indexPath];
            }
            else
            {
                cell.mainImageView.image = kamcordVideo.thumbnailImage;
            }
        }
    }
    
    // This gives a slight dark gradient at the bottom of the Thumbnails
    // so that the video Titles are readable
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = cell.bounds;
    
    UIColor *startcolor = [UIColor colorWithHue:kStartColorHue saturation:kStartColorSat brightness:kStartColorBri alpha:kStartColorAlpha];
    UIColor *endcolor = [UIColor colorWithHue:kEndColorHue saturation:kEndColorSat brightness:kEndColorBri alpha:kEndColorAlpha];
    
    gradient.colors = [NSArray arrayWithObjects:(id)[startcolor CGColor], (id)[endcolor CGColor], nil];
    cell.mainImageView.layer.sublayers = @[gradient]; // The gradient sublayer should always be the only sublayer
    
    // This decides the font used based on iOS device
    switch (UIDevice.currentDevice.userInterfaceIdiom)
    {
        case UIUserInterfaceIdiomPad:
            cell.title.font = [UIFont fontWithName:@"Helvetica Bold" size:kTitleFontSizeiPad];
            break;
        case UIUserInterfaceIdiomPhone:
            cell.title.font = [UIFont fontWithName:@"Helvetica Bold" size:kTitleFontSizeiPhone];
            break;
        default:
            cell.title.font = [UIFont fontWithName:@"Helvetica Bold" size:kTitleFontSizeiPhone];
            break;
    }
    
    return cell;
}


#pragma mark - UITableView


- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    [self deleteAllData];
}


#pragma mark - Interface Orientation


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (BOOL)shouldAutorotate
{
    return YES;
}


@end
