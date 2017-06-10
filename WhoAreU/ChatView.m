//
//  ChatView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 29..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "ChatView.h"
#import "MediaPicker.h"
#import "MessageCenter.h"
#import "ChatRow.h"

@interface ChatView() <UITextViewDelegate>
// System
@property (readonly) NSArray *messages;
@property (strong, nonatomic) id channelId;

@property (readonly, nonatomic) NSUInteger numberOfUsers;
@property (readonly, nonatomic) NSIndexPath* lastIndexPath;

// User interface
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) UIButton *mediaBut, *sendBut;
@property (strong, nonatomic) UIView *border;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIView* inputView;
@property (nonatomic) CGFloat height, keyboardHeight;
@property (nonatomic) BOOL keyboardUp;
@end

@implementation ChatView


- (void)reloadDataAnimated:(BOOL) animated
{
    [self.tableView reloadData];
    [self scrollToBottomAnimated:animated];
}

- (void)setChannel:(id)channel
{
    // Entry point to everything.
    
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
    if (self.messages.count > 0) {
        [self.tableView scrollToRowAtIndexPath:self.lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

- (NSIndexPath*) lastIndexPath
{
    NSUInteger count = self.messages.count;
    return [NSIndexPath indexPathForRow:count-1  inSection:0];

//    NSUInteger sections = self.sections.count - 1;
//    NSUInteger rows = [self messagesForSection:sections].count - 1;
//    
//    return [NSIndexPath indexPathForRow:rows inSection:sections];
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
    Notification(UIKeyboardWillChangeFrameNotification, doKeyBoardEvent:);
    Notification(UIKeyboardWillShowNotification, doKeyboardShowEvent:);
    Notification(UIKeyboardWillHideNotification, doKeyboardHideEvent:);
    Notification(kNotificationNewChatMessage, notificationNewChatMessage:);
    Notification(kNotificationReadMessage, notificationReadMessage:);
    Notification(kNotificationApplicationActive, notificationApplicationActive:);
    Notification(kNotificationEndEditing, notificationEndEditing:);
}

- (void)notificationEndEditing:(id)sender
{
    [self endEditing:YES];
}

- (void)notificationApplicationActive:(NSNotification*)notification
{
    __LF
    
//    [MessageCenter acknowledgeReadsForChannelId:self.channelId];
}

- (void)notificationReadMessage:(NSNotification*)notification
{
    __LF
    NSLog(@"=======================================");
    id channelId = notification.object[fChannelId];
    NSArray* reads = notification.object[fMessageIds];
    
    NSLog(@"Refreshing %@", reads);
    
    if (![self.channelId isEqualToString:channelId]) {
        return;
    }
    else {
        [self.tableView reloadData];
    }
}

- (void)notificationNewChatMessage:(NSNotification*)notification
{
    __LF
    NSLog(@"=======================================");
    [self reloadDataAnimated:YES];
}

- (void) dealloc
{
    __LF
    RemoveAllNotifications;
//    RNotification(UIKeyboardWillChangeFrameNotification);
//    RNotification(UIKeyboardWillShowNotification);
//    RNotification(UIKeyboardWillHideNotification);
//    RNotification(kNotificationNewChatMessage);
//    RNotification(kNotificationApplicationActive);
//    RNotification(kNotificationEndEditing);
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
    CGRect keyboardEndFrame;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardEndFrame];
    
    keyboardEndFrame = [[UIApplication sharedApplication].keyWindow convertRect:keyboardEndFrame toView:self];
    
    self.keyboardHeight = CGRectGetHeight(keyboardEndFrame);
    
    double transitionDuration;
    [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&transitionDuration];
    
    UIViewAnimationCurve transitionCurve;
    [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&transitionCurve];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:transitionDuration
                              delay:0.0f
                            options:transitionCurve << 16
                         animations:^{
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
    self.tableView = [[UITableView alloc] initWithFrame:self.frame style:UITableViewStyleGrouped];
    
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
    if ([self.textView.text isEqualToString:kStringNull]) {
        return;
    }
    
    NSString *string = self.textView.text;
    
    [MessageCenter send:string
              channelId:self.channelId
                  count:self.numberOfUsers
             completion:^(id messageId) {
                 NSLog(@"Last function");
                 [self reloadDataAnimated:YES];
             }];
    self.textView.text = kStringNull;
    [self textViewDidChange:self.textView];
}

- (void)mediaButPressed:(id)sender
{
    [self endEditing:YES];
    [MediaPicker pickMediaOnViewController:self.parent withUserMediaHandler:^(Media *media, BOOL picked) {
        if (picked) {
            [MessageCenter send:media
                      channelId:self.channelId
                          count:self.numberOfUsers
                     completion:^(id messageId) {
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
    
    CGRect rect = [textView.text boundingRectWithFont:textView.font maxWidth:CGRectGetWidth(textView.frame)-INSET];
    
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
//    NSLog(@"SECTIONS:%ld", self.sections.count);
//    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.channelId) {
        return self.messages.count;
//        NSLog(@"MESSAGES[%ld]:%ld", section, [self messagesForSection:section].count);
//        return [self messagesForSection:section].count;
    }
    else {
        return 0;
    }
}
/*
- (NSArray*) sections
{
    NSMutableOrderedSet *dates = [NSMutableOrderedSet orderedSetWithArray:self.chats.allKeys];
    [dates sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        if (obj1 > obj2)
            return NSOrderedDescending;
        else if ([obj1 isEqual:obj2])
            return NSOrderedSame;
        else
            return NSOrderedAscending;
    }];
    return [[dates set] allObjects];
}

- (NSArray*) messagesForSection:(NSUInteger)section
{
    id date = [self.sections objectAtIndex:section];
    
    if (self.sections.count>0) {
        return [self.chats objectForKey:date];
    }
    else {
        return nil;
    }
}
 */
//- (NSArray*) sections
//{
//    NSMutableOrderedSet *dates = [NSMutableOrderedSet orderedSet];
//    [self.messages enumerateObjectsUsingBlock:^(id _Nonnull dictionary, NSUInteger idx, BOOL * _Nonnull stop) {
//        
//        NSDate *date = [[dictionary objectForKey:fCreatedAt] dateWithoutTime];
//        
//        [dates addObject:date];
//    }];
//
//    return [[dates set] allObjects];
//}
//
//- (NSArray*) messagesForSection:(NSUInteger)section
//{
//    NSArray *sections = self.sections;
//    
//    if (sections.count>0) {
//        NSDate *dateForSection = [sections objectAtIndex:section];
//        NSArray *messages = [self.messages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"createdAt.dateWithoutTime == %@", dateForSection]];
//        
//        return messages;
//    }
//    else {
//        return nil;
//    }
//}
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatRow *cell = [tableView dequeueReusableCellWithIdentifier:@"RowCell" forIndexPath:indexPath];

    id message = [self.messages objectAtIndex:indexPath.row];
//    id message = [[self messagesForSection:indexPath.section] objectAtIndex:indexPath.row];
    
    [MessageCenter processReadMessage:message];
    cell.dictionary = message;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    id dictionary = [[self messagesForSection:indexPath.section] objectAtIndex:indexPath.row];
    id dictionary = [self.messages objectAtIndex:indexPath.row];

    id fromUser = [dictionary objectForKey:fFromUser];
    id fromUserId = fromUser[fObjectId];
    MessageType type = [[dictionary objectForKey:fType] integerValue];
    id message = [dictionary objectForKey:fMessage];
    id media = [dictionary objectForKey:fMedia];
    CGSize size = CGSizeFromString([media objectForKey:fSize]);
    
    BOOL isMine = [User meEquals:fromUserId];
    CGFloat room = isMine ? 2.5 : 5;
    
    switch (type) {
        case kMessageTypeText: {
            CGRect rect = [message boundingRectWithFont:chatFont maxWidth:CHATMAXWIDTH];
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

/*
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
    __LF
    NSString *date = [self.sections objectAtIndex:section];
    CGFloat w = CGRectGetWidth(self.bounds);
    
    UIView *header = [UIView new];
    header.frame = CGRectMake(0, 0, w, kChatViewHeaderHeight);
    header.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];

    UILabel *headerLabel = [UILabel new];
    headerLabel.frame = header.bounds;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.font = kChatViewHeaderFont;
    headerLabel.text = date;
    [header addSubview:headerLabel];
    
    return header;
}
 
 */

@end
