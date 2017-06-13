//
//  FollowCell.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 3..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "FollowCell.h"
#import "FollowingUserCell.h"

#define INSET 10

@interface FollowCell() <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) id nickname;
@property (nonatomic) FollowCellType type;
@end

@implementation FollowCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.collectionView registerNibNamed:@"FollowingUserCell"];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
}

- (void)setNickname:(id)nickname type:(FollowCellType)type
{
    _nickname = nickname;
    _type = type;
    
    switch (self.type) {
        case FollowCellTypeFollows:
            self.titleLabel.attributedText = [self followsString];
            break;
            
        default:
            self.titleLabel.attributedText = [self followingString];
            break;
    }
}

- (NSAttributedString*) followsString
{
    id attrMedium = @{
                      NSFontAttributeName : [UIFont systemFontOfSize:15 weight:UIFontWeightMedium],
                      };
    id attrBold = @{
                    NSFontAttributeName : [UIFont systemFontOfSize:15 weight:UIFontWeightBold],
                    };
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:self.nickname attributes:attrBold];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:@" is following" attributes:attrMedium]];
    
    return string;
}


- (NSAttributedString*) followingString
{
    id attr1 = @{
                 NSForegroundColorAttributeName : [UIColor blackColor],
                 NSFontAttributeName : [UIFont systemFontOfSize:15 weight:UIFontWeightBold],
                 };
    id attr2 = @{
                 NSForegroundColorAttributeName : [UIColor colorWithWhite:0.2 alpha:1.0],
                 NSFontAttributeName : [UIFont systemFontOfSize:15 weight:UIFontWeightMedium],
                 };

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"users following " attributes:attr2];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:self.nickname attributes:attr1]];
    
    return string;
}

- (void)setUsers:(NSArray<User *> *)users
{
    _users = users;
    
    [self.collectionView reloadData];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.users.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat h = CGRectGetHeight(collectionView.frame) - INSET*2.0f;
    return CGSizeMake(h, h);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return INSET;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return INSET;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(INSET, INSET, INSET, INSET);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FollowingUserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FollowingUserCell" forIndexPath:indexPath];
    
    cell.user = [self.users objectAtIndex:indexPath.row];
    cell.photoAction = self.photoAction;
    return cell;
}

@end
