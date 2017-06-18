//
//  MediaSlide.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 1..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "MediaPage.h"
#import "MediaPageCell.h"

@interface MediaPage() <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray <Media*> *items;
@property (strong, nonatomic) UIPageControl *page;
@property (strong, nonatomic) UIButton *left, *right;
@property (strong, nonatomic) UIProgressView *progress;
@property (nonatomic) NSUInteger index;
@end

@implementation MediaPage

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    self.items = [NSMutableArray new];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.contentInset = UIEdgeInsetsZero;
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsZero;
    self.collectionView.pagingEnabled = YES;
    self.collectionView.alwaysBounceHorizontal = YES;
    self.collectionView.bounces = YES;
    self.collectionView.scrollEnabled = YES;
    
    [self.collectionView registerNibNamed:@"MediaPageCell"];
    
    self.page = [UIPageControl new];
    [self.page addTarget:self action:@selector(pageSelected:) forControlEvents:UIControlEventValueChanged];
    
    self.left = [UIButton new];
    self.left.tag = -1;
    [self.left setImage:[UIImage imageNamed:@"left-chevron"] forState:UIControlStateNormal];
    [self.left setTintColor:[UIColor whiteColor]];
    [self.left addTarget:self action:@selector(scrollTo:) forControlEvents:UIControlEventTouchUpInside];

    self.right = [UIButton new];
    self.right.tag = 1;
    [self.right setImage:[UIImage imageNamed:@"right-chevron"] forState:UIControlStateNormal];
    [self.right setTintColor:[UIColor whiteColor]];
    [self.right addTarget:self action:@selector(scrollTo:) forControlEvents:UIControlEventTouchUpInside];
    
    self.progress = [UIProgressView new];
    
    [self addSubview:self.collectionView];
    [self addSubview:self.page];
    [self addSubview:self.left];
    [self addSubview:self.right];
    [self addSubview:self.progress];
}

- (void) scrollTo:(UIButton*)sender
{
    if (self.items.count == 0) {
        return;
    }
    NSInteger index = self.page.currentPage + sender.tag;
    index = (index + self.items.count) % self.items.count;
    self.page.currentPage = index;
    [self pageSelected:self.page];
}

- (void) pageSelected:(UIPageControl*)page
{
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:page.currentPage inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGPoint offset = scrollView.contentOffset;
    CGFloat x = offset.x, w = CGRectGetWidth(self.bounds);
    NSUInteger index = x/w;
    self.page.currentPage = index;
}

- (void)setUser:(User *)user
{
    [self clearArrays];
    
    _user = user;
    if (self.user) {
        if (self.user.media) {
            [self.items addObject:self.user.media];
        }
        [self.items addObjectsFromArray:self.user.photos];
        
        Counter *counter = [Counter counterWithCount:self.items.count completion:^{
            [UIView animateWithDuration:1 animations:^{
                self.progress.alpha = 0.0f;
            }];
        }];
        
        [self.items enumerateObjectsUsingBlock:^(Media * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            [item imageLoaded:^(UIImage *image) {
                self.progress.progress += 1.0/self.items.count;
                [counter decreaseCount];
            }];
        }];
    }
    
    self.page.numberOfPages = self.items.count;
    self.page.currentPage = 0;
    [self.collectionView reloadData];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MediaPageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MediaPageCell" forIndexPath:indexPath];
    
    cell.media = [self.items objectAtIndex:indexPath.row];
    return cell;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat w = CGRectGetWidth(self.bounds), h = CGRectGetHeight(self.bounds);
    return CGSizeMake(w, h);
}

- (void) clearArrays
{
    [self.items removeAllObjects];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect rect = self.bounds;
    CGFloat w = CGRectGetWidth(rect), h = CGRectGetHeight(rect), size = 30, offset = 20;
    self.collectionView.frame = rect;
    self.page.frame = CGRectMake(0, h-size, w, size);
    self.left.frame = CGRectMake(offset, (h-size)/2.0, size, size);
    self.right.frame = CGRectMake(w-offset-size, (h-size)/2.0, size, size);
    self.left.radius = size / 2.0f;
    self.right.radius = size / 2.0f;
    self.progress.frame = CGRectMake(0, h-2, w, 2);
}

@end
