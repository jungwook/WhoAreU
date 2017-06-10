//
//  MediaPageCell.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 3..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "MediaPageCell.h"
#import "PhotoView.h"

@interface MediaPageCell()
@property (weak, nonatomic) IBOutlet PhotoView *photoView;
@end

@implementation MediaPageCell

-(void)setMedia:(Media *)media
{
    _media = media;    
    [self.photoView setMedia:media];
}

@end
