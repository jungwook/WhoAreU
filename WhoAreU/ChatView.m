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

@interface NSDate (extensions)
- (NSDate *) dateWithoutTime;
@end

@implementation NSDate (extensions)

-(NSDate *) dateWithoutTime
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self];
    return [calendar dateFromComponents:components];
}

@end


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
    CGFloat inset = self.balloon.balloonInset;

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
        
        self.nickname.frame = CGRectMake(leftOffset+self.balloon.balloonInset, H-nh-2, nw, nh);
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
@property (weak, nonatomic) NSArray *sections;
@property (nonatomic) CGFloat height, keyboardHeight;
@property (nonatomic) BOOL keyboardUp;
@end

@implementation ChatView

static inline UIViewAnimationOptions AnimationOptionsForCurve(UIViewAnimationCurve curve)
{
    return curve << 16;
}

- (void)reloadDataAnimated:(BOOL) animated
{
    __LF
    
    [self.tableView reloadData];
    [self scrollToBottomAnimated:animated];
}

- (void) scrollToBottomAnimated:(BOOL)animated
{
    NSUInteger sections = self.sections.count - 1;
    NSUInteger rows = [self messagesForSection:sections].count - 1;
    if ([Engine messagesFromUser:self.user].count > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows inSection:sections] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
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
                                             selector:@selector(doKeyboardShowEvent:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(doKeyboardHideEvent:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newMessage:)
                                                 name:kNotificationNewUserMessage
                                               object:nil];
}

- (void)newMessage:(id)sender
{
    __LF
    [Engine loadUnreadMessagesFromUser:self.user completion:^{
        [self reloadDataAnimated:YES];
        [Engine setSystemBadge];
    }];
}

- (void) dealloc
{
    __LF
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationNewUserMessage object:nil];
}

- (void)doKeyboardShowEvent:(NSNotification *)notification
{
    self.keyboardUp = YES;
}

- (void)doKeyboardHideEvent:(NSNotification *)notification
{
    self.keyboardUp = NO;
}

- (void)doKeyBoardEvent:(NSNotification *)notification
{
    CGRect keyboardEndFrameWindow;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardEndFrameWindow];
    
    keyboardEndFrameWindow = [[UIApplication sharedApplication].keyWindow convertRect:keyboardEndFrameWindow toView:self];
    
    self.keyboardHeight = CGRectGetHeight(keyboardEndFrameWindow);
    
    double keyboardTransitionDuration;
    [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&keyboardTransitionDuration];
    
    UIViewAnimationCurve keyboardTransitionAnimationCurve;
    [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&keyboardTransitionAnimationCurve];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:keyboardTransitionDuration delay:0.0f options:AnimationOptionsForCurve(keyboardTransitionAnimationCurve) animations:^{
            [self setInputBarFrame];
            [self reloadDataAnimated:NO];
        } completion:nil];
    });
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
    CGFloat h = CGRectGetHeight(self.bounds);
    CGFloat baseLine, inputBarHeight = self.height;
    
    baseLine = h - inputBarHeight - (self.keyboardUp ? self.keyboardHeight : 0.0f);
    
    [self.tableView setFrame:CGRectMake(0, 0, w, baseLine)];
    [self.inputView setFrame:CGRectMake(0, baseLine, w, inputBarHeight)];
}

- (void) addTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.frame style:UITableViewStylePlain];
    
    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    self.tableView.backgroundColor = [UIColor whiteColor];
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
    
    [Engine send:textToSend toUser:self.user completion:^{
        [self reloadDataAnimated:YES];
    }];
}

- (void)mediaButPressed:(id)sender
{
    [MediaPicker pickMediaOnViewController:self.parent withUserMediaHandler:^(Media *media, BOOL picked) {
        if (picked) {
            [Engine send:media toUser:self.user completion:^{
                [self reloadDataAnimated:YES];
            }];
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
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.user) {
        return [self messagesForSection:section].count;
    }
    else {
        // Some other view controller is alive somewhere...
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatRow *cell = [tableView dequeueReusableCellWithIdentifier:@"RowCell" forIndexPath:indexPath];

    MessageDic *dictionary = [[self messagesForSection:indexPath.section] objectAtIndex:indexPath.row];
    
    cell.message = dictionary;
    cell.parent = self.parent;
    cell.user = self.user;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageDic *dictionary = [[self messagesForSection:indexPath.section] objectAtIndex:indexPath.row];

    BOOL isMine = [dictionary.fromUserId isEqualToString:[User me].objectId];
    CGFloat room = isMine ? 3 : 5;
    
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

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDate *date = [self.sections objectAtIndex:section];
    
    return [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSDate *date = [self.sections objectAtIndex:section];
    CGFloat w = CGRectGetWidth(self.bounds);
    
    UIView *header = [UIView new];
    header.frame = CGRectMake(0, 0, w, 40);
    UILabel *headerLabel = [UILabel new];
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.frame = header.bounds;
    headerLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    headerLabel.text = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
    [header addSubview:headerLabel];
    
    return header;
}

- (NSArray*) sections
{
    NSMutableSet *dates = [NSMutableSet set];
    NSArray *messages = [Engine messagesFromUser:self.user];
    [messages enumerateObjectsUsingBlock:^(MessageDic*  _Nonnull dictionary, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDate *date = dictionary.createdAt.dateWithoutTime;
        [dates addObject:date];
    }];
    
    return [[dates allObjects] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        if (obj1 > obj2)
            return NSOrderedDescending;
        else if (obj1 == obj2)
            return NSOrderedSame;
        else
            return NSOrderedAscending;
    }];
}

- (NSArray*) messagesForSection:(NSUInteger)section
{
    NSArray *sections = self.sections;
    
    if (sections.count>0) {
        NSDate *dateForSection = [sections objectAtIndex:section];
        NSArray *messages = [[Engine messagesFromUser:self.user] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"createdAt.dateWithoutTime == %@", dateForSection]];
        
        return messages;
    }
    else {
        return nil;
    }
}

@end
