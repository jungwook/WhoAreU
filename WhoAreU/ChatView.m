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


const CGFloat rightOffset = 20;
const CGFloat leftOffset = INSET+PHOTOVIEWSIZE+INSET;

@interface ChatRow : UITableViewCell
@property (weak, nonatomic) MessageDic *message;
@property (weak, nonatomic) User* user;
@property (weak, nonatomic) UIViewController *parent;

@property (strong, nonatomic) UILabel *nickname, *when;
@property (strong, nonatomic) PhotoView *photoView;
@property (strong, nonatomic) Balloon *balloon;
@property BOOL isMine;
@end

@implementation ChatRow

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.balloon = [Balloon new];
        
        self.photoView = [PhotoView new];
        self.photoView.backgroundColor = kAppColor;
        self.photoView.radius = PHOTOVIEWSIZE / 2.0f;
        self.photoView.borderWidth = 1.0f;
        self.photoView.borderColor = [UIColor blackColor];

        self.nickname = [UILabel new];
        self.nickname.font = [UIFont systemFontOfSize:12];

        self.when = [UILabel new];
        self.when.font = [UIFont systemFontOfSize:8];
        
        [self addSubview:self.balloon];
        [self addSubview:self.photoView];
        [self addSubview:self.nickname];
        [self addSubview:self.when];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setUser:(User *)user
{
    _user = user;
    
    self.photoView.media = user.media;
    self.nickname.text = user.nickname;
    [self.nickname sizeToFit];
}

- (void)setParent:(UIViewController *)parent
{
    self.balloon.parent = parent;
    self.photoView.parent = parent;
}

- (void)setMessage:(MessageDic*)message
{
    _message = message;
    
    BOOL isMine = [self.message.fromUserId isEqualToString:[User me].objectId];
    
    self.isMine = isMine;
    self.balloon.type = isMine ? kBalloonTypeRight : kBalloonTypeLeft;
    self.balloon.message = self.message;
    
    self.when.text = [NSDateFormatter localizedStringFromDate:message.createdAt dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    [self.when sizeToFit];
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat W = CGRectGetWidth(self.bounds);
    CGFloat H = CGRectGetHeight(self.bounds);
    CGFloat inset = self.balloon.ballonInset;

    CGFloat ww = CGRectGetWidth(self.when.frame);
    CGFloat wh = CGRectGetHeight(self.when.frame);
    CGFloat nw = CGRectGetWidth(self.nickname.frame);
    CGFloat nh = CGRectGetHeight(self.nickname.frame);

    CGFloat height = 0.f;
    CGFloat width = 0.f, offset = 0.f;
    
    switch (self.message.messageType) {
        case kMessageTypeText: {
            CGRect rect = __rectForString(self.message.message, chatFont, CHATMAXWIDTH);
            CGFloat w = CGRectGetWidth(rect);
            height = CGRectGetHeight(rect);
            width = w+2*INSET+inset;
            offset = self.isMine ? W-width-rightOffset : leftOffset;
        }
            break;
            
        case kMessageTypeMedia: {
            MediaDic *dic = self.message.media;
            width = MEDIASIZE;
            offset = self.isMine ? W-width-rightOffset : leftOffset;
            height = MEDIASIZE * dic.size.height / dic.size.width;
        }
            break;
            
        default:
            break;
    }
    
    self.balloon.frame = CGRectMake(offset, INSET, width, height+HINSET*3.0f);
    if (self.isMine) {
        self.when.frame = CGRectMake(offset - ww - HINSET, height+4*HINSET-wh, ww, wh);
    }
    else {
        self.when.frame = CGRectMake(offset + width + HINSET, 3*HINSET, ww, wh);
        self.photoView.frame = CGRectMake(INSET+3, H-PHOTOVIEWSIZE, PHOTOVIEWSIZE, PHOTOVIEWSIZE);
        
        self.nickname.frame = CGRectMake(leftOffset+self.balloon.ballonInset, H-nh-2, nw, nh);
    }

    self.photoView.alpha = !self.isMine;
    self.nickname.alpha = !self.isMine;
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

- (void)reloadDataAnimated:(BOOL) animated
{
    [self.tableView reloadData];
    [self scrollToBottomAnimated:animated];
}

- (void) scrollToBottomAnimated:(BOOL)animated
{
    NSUInteger rows = [Engine messagesFromUser:self.user].count;
    if (rows > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.translatesAutoresizingMaskIntoConstraints = YES;

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
}

- (void) dealloc
{
    __LF
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidEndEditingNotification object:nil];
}

- (void)doEndEditingEvent:(NSString *)string
{
    __LF
}

- (void)doKeyBoardEvent:(NSNotification *)notification
{
    CGRect keyboardEndFrameWindow;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardEndFrameWindow];
    
    keyboardEndFrameWindow = [[UIApplication sharedApplication].keyWindow convertRect:keyboardEndFrameWindow toView:self];
    
    double keyboardTransitionDuration;
    [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&keyboardTransitionDuration];
    
    UIViewAnimationCurve keyboardTransitionAnimationCurve;
    [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&keyboardTransitionAnimationCurve];
    
    self.baseLine = CGRectGetMinY(keyboardEndFrameWindow);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:keyboardTransitionDuration delay:0.0f options:AnimationOptionsForCurve(keyboardTransitionAnimationCurve) animations:^{
            [self setInputBarFrame];
            [self reloadDataAnimated:NO];
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
    
    self.tableView.allowsSelection = NO;
    
    [self.tableView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside:)]];
    
    [self.tableView registerClass:[ChatRow class] forCellReuseIdentifier:@"RowCell"];
    
    [self addSubview:self.tableView];
}

- (void) tappedOutside:(id)sender
{
    __LF
    [self endEditing:YES];
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
    
//    [Engine send:textToSend toUser:self.user completion:^{
//        [self reloadData];
//    }];
    
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
    __LF
    
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
    [self.tableView setFrame:CGRectMake(0, 0, w, baseLine-2)];
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
    
    CGRect rect = __rectForString(textView.text, textView.font, CGRectGetWidth(textView.frame)-8);
    
    NSUInteger nl = CGRectGetHeight(rect) / self.textView.font.lineHeight;
    
    nl = MIN(nl, maxLines);
    
    textView.scrollEnabled = (nl==maxLines);
    
    CGFloat tvh = TEXTVIEWHEIGHT+(nl-1)*(textView.font.lineHeight+2);
    
    if (nh != ph){
        self.height = tvh;
        [self setNeedsLayout];
        [self layoutIfNeeded];
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
    cell.user = self.user;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *messages = [Engine messagesFromUser:self.user];
    MessageDic *dictionary = [messages objectAtIndex:indexPath.row];
    
    BOOL isMine = [dictionary.fromUserId isEqualToString:[User me].objectId];
    CGFloat room = isMine ? 2 : 5;
    
    switch (dictionary.messageType) {
        case kMessageTypeText: {
            CGRect rect = __rectForString(dictionary.message, chatFont, CHATMAXWIDTH);
            
            return CGRectGetHeight(rect)+room*INSET;
        }
            break;
        case kMessageTypeMedia: {
            MediaDic *media = dictionary.media;
            CGFloat h = MEDIASIZE * media.size.height / media.size.width;
            return h+room*INSET;
        }
            
        default:
            return 44;
    }
    
}
@end
