//
//  MediaCollection.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 23..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "MediaCollection.h"
#import "PhotoView.h"

@interface MediaCell : UICollectionViewCell
@property (nonatomic, strong) PhotoView *photoView;
@end

@implementation MediaCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.photoView = [PhotoView new];
        self.photoView.radius = 4.0f;
        [self addSubview:self.photoView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.photoView.frame = self.bounds;
}

@end

@implementation MediaCollection

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.delegate = self;
    self.dataSource = self;
    
    [self registerClass:[MediaCell class] forCellWithReuseIdentifier:@"MediaCell"];
}

- (void)setUser:(User *)user
{
    NSLog(@"SEtting user:%@", user);
    _user = user;
    [self reloadData];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    __LF
    NSLog(@"Returning %ld cells", self.user.photos.count);
    return self.user.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MediaCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MediaCell" forIndexPath:indexPath];
    
    cell.photoView.media = [self.user.photos objectAtIndex:indexPath.row];
    cell.photoView.parent = self.parent;
    return cell;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(100, 100);
}

@end
