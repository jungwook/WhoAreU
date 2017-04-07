//
//  AddMediaSubView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 4..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "AddMediaSubView.h"
#import "S3File.h"

@interface DeletableMediaCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic, strong) Media *media;
@property (nonatomic, weak) id<DeletableMediaCellDelegate> delegate;
@end

@implementation DeletableMediaCell

void drawImage(UIImage *image, UIView* view)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [view.layer setContents:(id)image.CGImage];
        [view.layer setContentsGravity:kCAGravityResizeAspectFill];
        [view.layer setMasksToBounds:YES];
    });
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.radius = 4.0f;
    self.clipsToBounds = YES;
    self.layer.borderColor = [UIColor colorWithWhite:0.2 alpha:0.4].CGColor;
    self.layer.borderWidth = 4.0f;
    
    self.activity.hidden = NO;
    [self.activity startAnimating];
    
}

- (void)setMedia:(Media *)media
{
    drawImage(nil, self);
    _media = media;
    
    [S3File getDataFromFile:media.thumbnail dataBlock:^(NSData *data) {
        drawImage([UIImage imageWithData:data], self);
        [self.activity stopAnimating];
        self.activity.hidden = YES;
    }];
}

- (IBAction)deleteMedia:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(deleteUserMedia:)]) {
        [self.delegate deleteUserMedia:self.media];
    }
}

@end


@interface AddMediaSubView()
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSArray* media;
@end

@implementation AddMediaSubView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"MediaCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"MediaCell"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"AddMediaCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"AddMediaCell"];
}

- (IBAction)previousView:(id)sender {
    if (self.prevBlock) {
        self.prevBlock();
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.media.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.media.count) {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AddMediaCell" forIndexPath:indexPath];
        return cell;
    }
    else {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MediaCell" forIndexPath:indexPath];
        return cell;
    }
}

@end
