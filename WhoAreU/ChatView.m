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
#import "MessageCenter.h"
#import "MaterialDesignSymbol.h"

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
@property (weak, nonatomic) id dictionary;
@property (weak, nonatomic) User* user;
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

- (void)setDictionary:(id)dictionary
{
    _dictionary = dictionary;

    id fromUser = [dictionary objectForKey:fFromUser];
    id fromUserId = fromUser[fObjectId];
    id createdAt = [dictionary objectForKey:fCreatedAt];
    
    BOOL on = [[dictionary objectForKey:fSync] boolValue];
    
    BOOL isMine = [User meEquals:fromUserId];
    
    self.isMine = isMine;
    self.balloon.type = isMine ? kBalloonTypeRight : kBalloonTypeLeft;
    self.balloon.dictionary = self.dictionary;
    
    MaterialDesignSymbol *sending = [MaterialDesignSymbol iconWithCode:MaterialDesignIconCode.moreHoriz48px fontSize:8];
    [sending addAttribute:NSForegroundColorAttributeName value:self.balloon.backgroundColor];
    
    MaterialDesignSymbol *sent = [MaterialDesignSymbol iconWithCode:MaterialDesignIconCode.done48px fontSize:8];
    [sent addAttribute:NSForegroundColorAttributeName value:self.balloon.backgroundColor];
    
    
    NSString *dateString = [[NSDateFormatter localizedStringFromDate:createdAt dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle] stringByAppendingString:@" "];
    
    NSMutableAttributedString *status = [[NSMutableAttributedString alloc] initWithString:dateString];
    [status appendAttributedString:on ? sent.symbolAttributedString : sending.symbolAttributedString];
    self.when.attributedText = status;
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
    
    MessageType type = [[self.dictionary objectForKey:@"type"] integerValue];
    id message = [self.dictionary objectForKey:fMessage];
    id media = [self.dictionary objectForKey:fMedia];
    CGSize size = CGSizeFromString([media objectForKey:@"size"]);
    
    switch (type) {
        case kMessageTypeText: {
            CGRect rect = __rectForString(message, chatFont, CHATMAXWIDTH);
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
@property (readonly) NSArray *messages;
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) UIButton *mediaBut, *sendBut;
@property (strong, nonatomic) UIView *border;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIView* inputView;
@property (readonly) NSArray *sections;
@property (nonatomic) CGFloat height, keyboardHeight;
@property (nonatomic) BOOL keyboardUp;
@property (readonly) NSUInteger numberOfUsers;
@property (strong, nonatomic) id channelId;
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

- (void)setChannel:(id)channel
{
    _channel = channel;
    
    id channelId = self.channel[fObjectId];
    NSArray *users = self.channel[fUsers];
    
    _channelId = channelId;
    _numberOfUsers = users.count;
}

- (NSArray *)messages
{
    if (self.channelId) {
        NSArray *messages = [MessageCenter sortedMessagesForChannelId:self.channelId];
        return messages;
    }
    else {
        return nil;
    }
}

- (void) scrollToBottomAnimated:(BOOL)animated
{
    NSUInteger sections = self.sections.count - 1;
    NSUInteger rows = [self messagesForSection:sections].count - 1;
    if (self.messages.count > 0) {
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
    ANOTIF(UIKeyboardWillChangeFrameNotification, @selector(doKeyBoardEvent:));
    ANOTIF(UIKeyboardWillShowNotification, @selector(doKeyboardShowEvent:));
    ANOTIF(UIKeyboardWillHideNotification, @selector(doKeyboardHideEvent:));
    ANOTIF(kNotificationNewChatMessage, @selector(notificationNewChatMessage:));
}

- (void)notificationNewChatMessage:(NSNotification*)notification
{
    __LF
    NSLog(@"=======================================");
    NSLog(@"D:%@", notification);
    id message = notification.object;
    id channel = message[fChannel];
    if (![self.channelId isEqualToString:channel[fObjectId]]) {
        return;
    }
    else {
        [self reloadDataAnimated:YES];
    }
}

- (void) dealloc
{
    __LF
    
    RNOTIF(UIKeyboardWillChangeFrameNotification);
    RNOTIF(UIKeyboardWillShowNotification);
    RNOTIF(UIKeyboardWillHideNotification);
    RNOTIF(kNotificationNewChatMessage);
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
    [MessageCenter send:self.textView.text
              channelId:self.channelId
                  count:self.numberOfUsers
             completion:^(id object) {
        [self reloadDataAnimated:YES];
    }];
    [self reloadDataAnimated:YES];
    self.textView.text = @"";
    [self textViewDidChange:self.textView];
}

- (void)mediaButPressed:(id)sender
{
    [MediaPicker pickMediaOnViewController:self.parent withUserMediaHandler:^(Media *media, BOOL picked) {
        if (picked) {
            [MessageCenter send:media
                      channelId:self.channelId
                          count:self.numberOfUsers
                     completion:^(id object) {
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
    if (self.channelId) {
        return [self messagesForSection:section].count;
    }
    else {
        return 0;
    }
}

- (NSArray*) sections
{
    NSMutableOrderedSet *dates = [NSMutableOrderedSet orderedSet];
    [self.messages enumerateObjectsUsingBlock:^(id _Nonnull dictionary, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSDate *date = [[dictionary objectForKey:fCreatedAt] dateWithoutTime];
        
        [dates addObject:date];
    }];

    return [[dates set] allObjects];
}

- (NSArray*) messagesForSection:(NSUInteger)section
{
    NSArray *sections = self.sections;
    
    if (sections.count>0) {
        NSDate *dateForSection = [sections objectAtIndex:section];
        NSArray *messages = [self.messages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"createdAt.dateWithoutTime == %@", dateForSection]];
        
        return messages;
    }
    else {
        return nil;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatRow *cell = [tableView dequeueReusableCellWithIdentifier:@"RowCell" forIndexPath:indexPath];

    id dictionary = [[self messagesForSection:indexPath.section] objectAtIndex:indexPath.row];
    
    [MessageCenter processReadMessage:dictionary];
    
    cell.dictionary = dictionary;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id dictionary = [[self messagesForSection:indexPath.section] objectAtIndex:indexPath.row];

    id fromUser = [dictionary objectForKey:fFromUser];
    id fromUserId = fromUser[fObjectId];
    MessageType type = [[dictionary objectForKey:@"type"] integerValue];
    id message = [dictionary objectForKey:fMessage];
    id media = [dictionary objectForKey:fMedia];
    CGSize size = CGSizeFromString([media objectForKey:@"size"]);
    
    BOOL isMine = [User meEquals:fromUserId];
    CGFloat room = isMine ? 2.5 : 3;
    
    switch (type) {
        case kMessageTypeText: {
            CGRect rect = __rectForString(message, chatFont, CHATMAXWIDTH);
            
            return CGRectGetHeight(rect)+room*INSET;
        }
            break;
        case kMessageTypeMedia: {
            CGFloat h = MEDIASIZE * size.height / size.width;
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
    return kChatViewHeaderHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSDate *date = [self.sections objectAtIndex:section];
    CGFloat w = CGRectGetWidth(self.bounds);
    
    UIView *header = [UIView new];
    header.frame = CGRectMake(0, 0, w, kChatViewHeaderHeight);
    header.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];

    UILabel *headerLabel = [UILabel new];
    headerLabel.frame = header.bounds;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.font = kChatViewHeaderFont;
    headerLabel.text = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
    [header addSubview:headerLabel];
    
    return header;
}
@end
