//
//  MediaCollection.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 23..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "MediaCollection.h"
#import "PhotoView.h"
#import "MediaPicker.h"

@interface EmptyCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, copy) VoidBlock addMediaBlock;
@property (nonatomic) BOOL editable;
@end

@implementation EmptyCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.radius = 4.0f;
        self.clipsToBounds = YES;
//        self.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.4f];
        self.backgroundColor = [kAppColor colorWithAlphaComponent:0.4f];
        self.label = [[UILabel alloc] initWithFrame:frame];
        self.label.numberOfLines = 2;
        self.label.text = @"NO\nMEDIA";
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = [UIColor whiteColor];
        self.label.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        [self addSubview:self.label];
        
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.button addTarget:self action:@selector(addMedia:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:self.button];
    }
    return self;
}

- (void)setEditable:(BOOL)editable
{
    _editable = editable;
    
    self.label.text = self.editable ? @"ADD\nMEDIA" : @"NO\nMEDIA";
}

- (void) addMedia:(id)sender
{
    if (self.editable) {
        NSLog(@"ADDING MEDIA");
        if (self.addMediaBlock) {
            self.addMediaBlock();
        }
    }
    else {
        NSLog(@"NOT MINE");
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.label.frame = self.bounds;
    self.button.frame = self.bounds;
}

@end

@interface MediaCell : UICollectionViewCell
@property (nonatomic, strong) PhotoView *photoView;
@property (nonatomic, strong) UIButton *trashButton;
@property (nonatomic, weak) UIViewController* parent;
@property (nonatomic, weak) Media* media;
@property (nonatomic, copy) MediaBlock deleteBlock;
@property (nonatomic) BOOL editable;
@end

@implementation MediaCell

- (void)setEditable:(BOOL)editable
{
    _editable = editable;
    
    self.trashButton.alpha = editable;
}

- (void)setMedia:(Media *)media
{
    _media = media;
    self.photoView.media = media;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.photoView = [PhotoView new];
        self.photoView.radius = 4.0f;
        
        self.backgroundColor = [UIColor clearColor];
        [self createTrashButton];
        [self addSubview:self.photoView];
        [self addSubview:self.trashButton];
    }
    return self;
}

- (void) createTrashButton
{
    UIImage *trash = [[UIImage imageNamed:@"trash"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    self.trashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.trashButton.borderColor = [UIColor whiteColor];
    self.trashButton.borderWidth = 1.0f;
    self.trashButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4f];
    
    [self.trashButton setTintColor:[UIColor whiteColor]];
    [self.trashButton setImage:trash
                       forState:UIControlStateNormal];
    [self.trashButton addTarget:self
                          action:@selector(trashMedia:)
                forControlEvents:UIControlEventTouchUpInside];
}

- (void)trashMedia:(id)sender
{
    __alert(self.parent, @"Confirm Deletion", @"Do you really want to delete this photo?", ^(UIAlertAction *action) {
        if (self.deleteBlock) {
            self.deleteBlock(self.media);
        }
    }, ^(UIAlertAction *action) {});
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.bounds;
    CGFloat w = CGRectGetWidth(frame), h = CGRectGetHeight(frame), offset = 4, size = 20;
    
    self.photoView.frame = self.bounds;
    self.trashButton.frame = CGRectMake(w-offset-size, h-offset-size, size, size);
    self.trashButton.radius = size / 2.0f;
}

@end

#pragma mark MediaCollection

@interface MediaCollection()
@property (nonatomic, strong) NSMutableArray *media;

@end

@implementation MediaCollection

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
    self.delegate = self;
    self.dataSource = self;
    
    [self registerClass:[MediaCell class] forCellWithReuseIdentifier:@"MediaCell"];
    [self registerClass:[EmptyCell class] forCellWithReuseIdentifier:@"EmptyCell"];
    
    self.media = [NSMutableArray array];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
    flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    self = [super initWithFrame:frame collectionViewLayout:flow];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setUser:(User *)user
{
    [self.media removeAllObjects];
    _user = user;
    if (user) {
        if (!self.user.isMe) {
            [self.media addObject:user.media];
        }
        [self.media addObjectsFromArray:user.photos];
    }
    [self reloadData];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return MAX(self.media.count, 1);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.media.count == 0) {
        EmptyCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EmptyCell" forIndexPath:indexPath];
        cell.editable = self.user.isMe;
        cell.addMediaBlock = ^{
            [self addMedia];
        };
        return cell;
    }
    else {
        MediaCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MediaCell" forIndexPath:indexPath];
        
        cell.media = [self.media objectAtIndex:indexPath.row];
        cell.parent = self.parent;
        cell.editable = self.user.isMe;
        cell.deleteBlock = ^(Media *media) {
            NSUInteger idx = [self.media indexOfObject:media];
            NSLog(@"Deleting photo at index %ld", idx);
            [self.media removeObject:media];
            [self.user removeObjectsInArray:@[media] forKey:@"photos"];
            [self.user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    if (self.media.count > 0) {
                        [collectionView performBatchUpdates:^{
                            [collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]];
                        } completion:nil];
                    }
                    else {
                        [collectionView performBatchUpdates:^{
                            [collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]];
                        } completion:nil];
                    }
                }
            }];
        };
        return cell;
    }
}

- (void)addMedia
{
    void (^updateAction)(UIAlertAction * _Nonnull action) = ^(UIAlertAction * _Nonnull action){
        [MediaPicker pickMediaOnViewController:self.parent withUserMediaHandler:^(Media *media, BOOL picked) {
            if (picked) {
                [self.media addObject:media];
                [self.user addUniqueObject:media forKey:@"photos"];
                [self.user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        NSUInteger idx = [self.media indexOfObject:media];
                        if (idx == 0) {
                            [self performBatchUpdates:^{
                                [self reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]];
                            } completion:nil];
                        }
                        else {
                            [self performBatchUpdates:^{
                                [self insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]];
                            } completion:nil];
                        }
                    }
                }];
            }
        }];
    };
    void (^cancelAction)(UIAlertAction * action) = ^(UIAlertAction* action) {
    };
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Add Photo"
                                              style:UIAlertActionStyleDefault
                                            handler:updateAction]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:cancelAction]];
    [self.parent presentViewController:alert
                              animated:YES
                            completion:nil];
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat h = CGRectGetHeight(self.bounds), offset = 10;
    return CGSizeMake(h-offset, h-offset);
}

@end
