//
//  ChatView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 29..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "ChatView.h"
#import "MediaPicker.h"
#import "PhotoView.h"
#import "Balloon.h"

#define chatFont [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold]

const CGFloat rightOffset = 20;
const CGFloat leftOffset = 80;


@interface ChatRow : UITableViewCell
@property (weak, nonatomic) MessageDic *message;
@property (strong, nonatomic) UILabel *messageLabel;
@property (strong, nonatomic) PhotoView *photoView;
@property (strong, nonatomic) Balloon *balloon;
@property (weak, nonatomic) UIViewController *parent;
@property BOOL isMine;
@end

@implementation ChatRow

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.balloon = [Balloon new];
        
        self.messageLabel = [UILabel new];
        self.messageLabel.numberOfLines = FLT_MAX;
        self.messageLabel.font = chatFont;
        self.messageLabel.textColor = [UIColor whiteColor];
        
        self.photoView = [PhotoView new];
        self.photoView.backgroundColor = [UIColor whiteColor];
        
        [self addSubview:self.balloon];
        [self.balloon addSubview:self.messageLabel];
        [self.balloon addSubview:self.photoView];
    }
    return self;
}

- (UIViewController *)parent
{
    return self.photoView.parent;
}

- (void)setParent:(UIViewController *)parent
{
    self.photoView.parent = parent;
}

- (void)setMessage:(MessageDic*)message
{
    _message = message;
    
    BOOL isMine = [self.message.fromUserId isEqualToString:[User me].objectId] && (self.message.createdAt == self.message.updatedAt);
    
    if (isMine && [self.message.toUserId isEqualToString:[User me].objectId]) {
        isMine = NO;
    }
    self.isMine = isMine;
    self.balloon.isMine = isMine;
    
    switch (self.message.messageType) {
        case kMessageTypeMedia:
            self.photoView.mediaDic = message.media;
            self.messageLabel.alpha = 0.0f;
            self.photoView.alpha = 1.0f;
            break;
            
        case kMessageTypeText:
            self.messageLabel.text = message.message;
            self.messageLabel.alpha = 1.0f;
            self.photoView.alpha = 0.0f;
            break;
            
        default:
            break;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat W = CGRectGetWidth(self.bounds);
    
    switch (self.message.messageType) {
        case kMessageTypeText: {
            CGRect rect = __rectForString(self.message.message, chatFont, CHATMAXWIDTH);
            CGFloat w = CGRectGetWidth(rect);
            CGFloat h = CGRectGetHeight(rect);
            
            CGFloat balloonWidth = w+2*INSET+6;
            CGFloat balloonOffset = self.isMine ? W-balloonWidth-rightOffset : leftOffset;
            self.balloon.frame = CGRectMake(balloonOffset, INSET, balloonWidth, h+INSET);
            self.messageLabel.frame = CGRectMake(self.isMine ? INSET : INSET+6, 0, w, h + INSET);
        }
            break;
            
        case kMessageTypeMedia: {
            MediaDic *dic = self.message.media;
            CGFloat balloonOffset = self.isMine ? W-MEDIASIZE-rightOffset : leftOffset;
            CGFloat h = MEDIASIZE * dic.size.height / dic.size.width;
            self.balloon.frame = CGRectMake(balloonOffset, INSET, MEDIASIZE, h+INSET);
            self.photoView.frame = self.balloon.bounds;
        }
            break;
            
        default:
            break;
    }
}

@end

@interface ChatView() <UITextViewDelegate>
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) UIButton *mediaBut, *sendBut;
@property (strong, nonatomic) UIView *border;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIView* inputView;
@property CGFloat height, baseLine;
@end

@implementation ChatView

static inline UIViewAnimationOptions AnimationOptionsForCurve(UIViewAnimationCurve curve)
{
    return curve << 16;
}

- (void)reloadData
{
    [self.tableView reloadData];
    
    CGPoint offset = CGPointMake(0, self.tableView.contentSize.height - self.tableView.frame.size.height );
    [self.tableView setContentOffset:offset animated:YES];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addContents];
        self.height = TEXTVIEWHEIGHT;
        self.baseLine = CGRectGetHeight(frame);
    }
    return self;
}

- (void) addContents
{
    self.inputView = [UIView new];
    self.inputView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self addSubview:self.inputView];
    
    [self addTableView];
    [self addBorder];
    [self addMediaBut];
    [self addTextView];
    [self addSendBut];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(doKeyBoardEvent:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(doEndEditingEvent:)
                                                 name:UITextViewTextDidEndEditingNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newMessage:)
                                                 name:kNOTIFICATION_NEW_MESSAGE
                                               object:nil];

}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNOTIFICATION_NEW_MESSAGE object:nil];
}

- (void)newMessage:(id)sender
{
    [self.tableView reloadData];

    CGFloat y = self.tableView.contentSize.height - self.tableView.frame.size.height;
    CGPoint offset = CGPointMake(0, MAX(y, 0));
    [self.tableView setContentOffset:offset animated:YES];

}

- (void)doEndEditingEvent:(NSString *)string
{
    __LF
}

- (void)doKeyBoardEvent:(NSNotification *)notification
{
    CGRect keyboardEndFrameWindow;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardEndFrameWindow];
    
    double keyboardTransitionDuration;
    [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&keyboardTransitionDuration];
    
    UIViewAnimationCurve keyboardTransitionAnimationCurve;
    [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&keyboardTransitionAnimationCurve];
    
    self.baseLine = CGRectGetMinY(keyboardEndFrameWindow);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:keyboardTransitionDuration delay:0.0f options:AnimationOptionsForCurve(keyboardTransitionAnimationCurve) animations:^{
            [self setInputBarFrame];
        } completion:nil];
    });
}

- (void) addTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.frame style:UITableViewStylePlain];
    
    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.tableView registerClass:[ChatRow class] forCellReuseIdentifier:@"RowCell"];
    
    [self addSubview:self.tableView];
}

- (void) addBorder
{
    self.border = [UIView new];
    self.border.backgroundColor = [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:205.0/255.0 alpha:1.0];
    [self.inputView addSubview:self.border];
}

- (void) addMediaBut
{
    self.mediaBut = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.mediaBut setTitle:@"+" forState:UIControlStateNormal];
    self.mediaBut.titleLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightThin];
    [self.mediaBut addTarget:self action:@selector(mediaButPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.inputView addSubview:self.mediaBut];
}

- (void) addSendBut
{
    __LF
    self.sendBut = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sendBut setTitle:@"SEND" forState:UIControlStateNormal];
    [self.sendBut addTarget:self action:@selector(sendButPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.inputView addSubview:self.sendBut];
}

- (void)sendButPressed:(id)sender
{
    NSString *textToSend = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.textView.text = @"";
    [self textViewDidChange:self.textView];
    if (self.sendTextAction)
    {
        self.sendTextAction(textToSend);
    }
}

- (void)mediaButPressed:(id)sender
{
    [MediaPicker pickMediaOnViewController:self.parent withUserMediaHandler:^(Media *media, BOOL picked) {
        if (picked && self.sendMediaAction) {
            self.sendMediaAction(media);
        }
    }];
}

- (void) addTextView
{
    self.textView = [UITextView new];
    
    self.textView.delegate = self;
    self.textView.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.textView.backgroundColor = [UIColor whiteColor];
    
    self.textView.keyboardType = UIKeyboardTypeDefault;
    self.textView.returnKeyType = UIReturnKeyNext;
    self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textView.spellCheckingType = UITextSpellCheckingTypeNo;
    self.textView.enablesReturnKeyAutomatically = YES;
    self.textView.scrollEnabled = NO;
    self.textView.layer.cornerRadius = 2.0;
    self.textView.layer.borderWidth = 0.5;
    self.textView.layer.borderColor =  [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:205.0/255.0 alpha:1.0].CGColor;
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    self.textView.textContainerInset = UIEdgeInsetsMake(8, 0, 8, 0);
    self.textView.contentInset = UIEdgeInsetsZero;
    
    // view hierachy
    [self.inputView addSubview:self.textView];
}

- (void)layoutSubviews
{
    const CGFloat offset = 4;
    
    [super layoutSubviews];
    
    CGFloat w = CGRectGetWidth(self.frame);
    
    [self setInputBarFrame];
    
    [self.border setFrame:CGRectMake(0, 0, w, 0.5)];
    [self.mediaBut setFrame:CGRectMake(offset,
                                       self.height-LEFTBUTSIZE,
                                       LEFTBUTSIZE-2*offset,
                                       LEFTBUTSIZE-2*offset)];
    [self.textView setFrame:CGRectMake(LEFTBUTSIZE,
                                       INSET,
                                       w-LEFTBUTSIZE-INSET-SENDBUTSIZE-INSET,
                                       self.height-2*INSET)];
    [self.sendBut setFrame:CGRectMake(
                                      w-SENDBUTSIZE-INSET,
                                      self.height-LEFTBUTSIZE, SENDBUTSIZE, LEFTBUTSIZE-2*offset)];
}

- (void) setInputBarFrame
{
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat baseLine = self.baseLine - self.height;
    [self.tableView setFrame:CGRectMake(0, 0, w, baseLine)];
    [self.inputView setFrame:CGRectMake(0, baseLine, w, self.height)];
}

- (void)textViewDidChange:(UITextView *)textView
{
    const NSUInteger maxLines = 6;
    static CGRect previousRect;
    
    UITextPosition* pos = textView.endOfDocument;
    CGRect currentRect = [textView caretRectForPosition:pos];
    
    CGFloat nh = CGRectGetMinY(currentRect)+CGRectGetHeight(currentRect);
    CGFloat ph = CGRectGetMinY(previousRect)+CGRectGetHeight(previousRect);
    
    CGRect rect = __rectForString(textView.text, textView.font, textView.frame.size.width);
    
    NSUInteger nl = CGRectGetHeight(rect) / self.textView.font.lineHeight;
    
    nl = MIN(nl, maxLines);
    
    textView.scrollEnabled = (nl==maxLines);
    
    CGFloat tvh = TEXTVIEWHEIGHT+(nl-1)*(textView.font.lineHeight+2);
    
    if (nh != ph){
        self.height = tvh;
        [self setNeedsLayout];
    }
    
    previousRect = currentRect;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.user) {
        return [Engine messagesFromUser:self.user].count;
    }
    else {
        // Some other view controller is alive somewhere...
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatRow *cell = [tableView dequeueReusableCellWithIdentifier:@"RowCell" forIndexPath:indexPath];

    NSArray *messages = [Engine messagesFromUser:self.user];
    cell.message = [messages objectAtIndex:indexPath.row];
    cell.parent = self.parent;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *messages = [Engine messagesFromUser:self.user];
    MessageDic *dictionary = [messages objectAtIndex:indexPath.row];
    switch (dictionary.messageType) {
        case kMessageTypeText: {
            CGRect rect = __rectForString(dictionary.message, chatFont, CHATMAXWIDTH);
            return CGRectGetHeight(rect)+3*INSET;
        }
            break;
        case kMessageTypeMedia: {
            MediaDic *media = dictionary.media;
            CGFloat h = MEDIASIZE * media.size.height / media.size.width;
            return h+3*INSET;
        }
            
        default:
            return 44;
    }
    
}
@end
