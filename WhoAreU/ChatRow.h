//
//  ChatRow.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 20..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoView.h"
#import "Balloon.h"
#import "MaterialDesignSymbol.h"


@interface ChatRow : UITableViewCell
@property (weak, nonatomic) id dictionary;
@property (strong, nonatomic) UILabel *nickname, *when, *read;
@property (strong, nonatomic) PhotoView *photoView;
@property (strong, nonatomic) Balloon *balloon;
@property BOOL isMine;
@end

