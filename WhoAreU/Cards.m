//
//  Cards.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 29..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Cards.h"
#import "Collection.h"
#import "HeaderMenu.h"

@interface Cards ()
@property (nonatomic, strong) NSArray <User*>*users;
@property (weak, nonatomic) IBOutlet Collection *collectionView;
@end

@implementation Cards

static NSString * const reuseIdentifier = @"Card";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.visibleCellChangedBlock = ^(__kindof UICollectionViewCell *cell) {
        [(Card*)cell playVideoIfVideo];
    };
    
    self.collectionView.backgroundColor = [UIColor groupTableViewBackgroundColor];
//    self.collectionView.backgroundColor = [[UIColor appColor] colorWithAlphaComponent:0.4];
    [self.collectionView registerNibNamed:reuseIdentifier];
    // Do any additional setup after loading the view.
    PFQuery *query = [User query];
    [query includeKey:fMedia];
    [query whereKey:fGender equalTo:@(kGenderTypeMale)];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        self.users = objects;
        [self.collectionView reloadData];
    }];
    
    HeaderMenu *menu = [HeaderMenu menuWithTabBarItems:@[
                                                         @{
                                                             fTitle : @"Users",
                                                             fIcon : @"pin",
                                                             fDeselectedIcon : @"pin",
                                                             },
                                                         @{
                                                             //                          fTitle : @"Me",
                                                             fIcon : @"user",
                                                             fDeselectedIcon : @"user",
                                                             },
                                                         @{
                                                             //                          fTitle : @"Me",
                                                             fIcon : @"heart",
                                                             fDeselectedIcon : @"heart",
                                                             },
                                                         @{
                                                             //                          fTitle : @"Chat",
                                                             fIcon : @"message2",
                                                             fDeselectedIcon : @"message2",
                                                             },
                                                         @{
                                                             //                          fTitle : @"Channel",
                                                             fIcon : @"pin2",
                                                             fDeselectedIcon : @"pin2",
                                                             },
                                                         ]];
    
    menu.frame = CGRectMake(0, 0, self.view.bounds.size.width, 60.f);
    menu.backgroundColor = [UIColor appColor];
    [self.collectionView addSubview:menu];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return self.users.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Card *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    User *user = [self.users objectAtIndex:indexPath.row];
    cell.user = user;
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat inset = 8.f, barHeight = 44.f, tabBarHeight = 0.f;
    User *user = [self.users objectAtIndex:indexPath.row];
    BOOL nointro = user.introduction == nil || [user.introduction isEqualToString:kStringNull];

    CGFloat width = CGRectGetWidth(collectionView.bounds); //-inset-inset;
    CGFloat imageHeight = [user.media heightWithWidth:width]; // == 0 ? width/2.0f : [user.media heightWithWidth:width];
    CGFloat introductionHeight = [user.introduction heightWithFont:[UIFont systemFontOfSize:14 weight:UIFontWeightMedium] maxWidth:width] + inset + inset;
    
    introductionHeight += nointro ? - inset*4.f : 0.f;
    
    CGFloat height = barHeight + tabBarHeight + barHeight + imageHeight + introductionHeight;
    
    return CGSizeMake(width, height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(8, 0, 8, 0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 8;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 8;
}

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
}

@end
