//
//  ChatRow.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 20..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "ChatRow.h"

const CGFloat rightOffset = 20;
const CGFloat leftOffset = INSET+PHOTOVIEWSIZE+INSET;

@implementation ChatRow

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.balloon = [Balloon new];
        
        self.photoView = [PhotoView new];
        self.photoView.backgroundColor = kAppColor;
        self.photoView.radius = PHOTOVIEWSIZE / 2.0f;
        
        self.nickname = [UILabel new];
        self.nickname.font = [UIFont systemFontOfSize:12];
        
        self.when = [UILabel new];
        self.when.font = [UIFont systemFontOfSize:10];
        
        self.read = [UILabel new];
        self.read.font = [UIFont boldSystemFontOfSize:10];
        
        [self addSubview:self.balloon];
        [self addSubview:self.photoView];
        [self addSubview:self.nickname];
        [self addSubview:self.when];
        [self addSubview:self.read];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setDictionary:(id)dictionary
{
    _dictionary = dictionary;
    
    id fromUser = [dictionary objectForKey:fFromUser];
    id fromUserId = fromUser[fObjectId];
    id createdAt = [dictionary objectForKey:fCreatedAt];
    id nickname = fromUser[fNickname];
    
    BOOL isMine = [User meEquals:fromUserId];
    
    self.isMine = isMine;
    self.balloon.type = isMine ? kBalloonTypeRight : kBalloonTypeLeft;
    self.balloon.dictionary = self.dictionary;
    
    NSUInteger readCount = [self.dictionary[fRead] integerValue];
    
    NSString *dateString = [NSDateFormatter localizedStringFromDate:createdAt dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    
    self.when.text = dateString;
    self.nickname.text = nickname;
    
    [self.nickname sizeToFit];
    [self.when sizeToFit];
    
    self.read.text = readCount > 0 ? @(readCount).stringValue : kStringNull;
    self.read.textColor = self.balloon.backgroundColor;
    [self.read sizeToFit];
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat W = CGRectGetWidth(self.bounds);
    CGFloat H = CGRectGetHeight(self.bounds);
    CGFloat inset = self.balloon.balloonInset;
    
    CGFloat ww = CGRectGetWidth(self.when.frame);
    CGFloat wh = CGRectGetHeight(self.when.frame);
    
    CGFloat rw = CGRectGetWidth(self.read.frame);
    CGFloat rh = CGRectGetHeight(self.read.frame);
    
    CGFloat nw = CGRectGetWidth(self.nickname.frame);
    CGFloat nh = CGRectGetHeight(self.nickname.frame);
    
    CGFloat height = 0.f;
    CGFloat width = 0.f, offset = 0.f;
    
    MessageType type = [[self.dictionary objectForKey:fType] integerValue];
    id message = [self.dictionary objectForKey:fMessage];
    id media = [self.dictionary objectForKey:fMedia];
    CGSize size = CGSizeFromString([media objectForKey:fSize]);
    
    switch (type) {
        case kMessageTypeText: {
            CGRect rect = [message boundingRectWithFont:chatFont maxWidth:CHATMAXWIDTH];
            CGFloat w = CGRectGetWidth(rect);
            height = CGRectGetHeight(rect);
            width = w+2*INSET+inset;
            offset = self.isMine ? W-width-rightOffset : leftOffset;
        }
            break;
            
        case kMessageTypeMedia: {
            width = MEDIASIZE;
            offset = self.isMine ? W-width-rightOffset : leftOffset;
            height = MEDIASIZE * size.height / size.width;
        }
            break;
            
        default:
            break;
    }
    
    self.balloon.frame = CGRectMake(offset, INSET, width, height+HINSET*3.0f);
    if (self.isMine) {
        //        self.when.frame = CGRectMake(offset - ww - HINSET, height+4*HINSET-wh, ww, wh);
        self.when.frame = CGRectMake(offset - ww - HINSET, 3*HINSET, ww, wh);
        self.read.frame = CGRectMake(offset - rw - HINSET, 6*HINSET, rw, rh);
    }
    else {
        self.when.frame = CGRectMake(offset + width + HINSET, 3*HINSET, ww, wh);
        self.photoView.frame = CGRectMake(INSET+3, H-PHOTOVIEWSIZE, PHOTOVIEWSIZE, PHOTOVIEWSIZE);
        self.nickname.frame = CGRectMake(leftOffset+self.balloon.balloonInset, H-nh-2, nw, nh);
        self.read.frame = CGRectMake(offset +width + HINSET, 6*HINSET, rw, rh);
    }
    
    self.photoView.alpha = !self.isMine;
    self.nickname.alpha = !self.isMine;
}

@end
