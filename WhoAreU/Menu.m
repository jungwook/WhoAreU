//
//  Menu.m
//  LetsMeet
//
//  Created by 한정욱 on 2016. 5. 13..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import "Menu.h"

@interface MenuCell : UITableViewCell
@property (nonatomic, strong) UIImage *icon;
@property (nonatomic, strong) NSString *menu;
@end

@interface MenuCell()
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *menuLabel;
@end

@implementation MenuCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor clearColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    [self highlightCell:selected];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    [self highlightCell:highlighted];
}

- (void)highlightCell:(BOOL)highlight {
    UIColor *tintColor = [UIColor whiteColor];
    if(highlight) {
        tintColor = [UIColor colorWithWhite:1.0 alpha:0.6];
    }
    
    self.menuLabel.textColor = tintColor;
    self.iconView.tintColor = tintColor;
}


- (NSString*) menu {
    return self.menuLabel.text;
}

- (void) setMenu:(NSString *)menu
{
    [self.menuLabel setText:menu];
}

- (UIImage *) icon {
    return self.iconView.image;
}

- (void) setIcon:(UIImage *)icon {
    self.iconView.image = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

@end


@interface Menu ()

@end

@implementation Menu

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"MenuCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"MenuCell"];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.contentInset = UIEdgeInsetsMake(140.F, 0.0F, 0.0F, 0.0F);
    self.clearsSelectionOnViewWillAppear = NO;
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.menuController.screens allKeys] count];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MenuCell* cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
    NSDictionary *screens = self.menuController.screens;
    
    id key = [screens allKeys][indexPath.row];
    id obj = screens[key][@"menu"];
    id icn = screens[key][@"icon"];
    cell.menu = obj;
    cell.icon = [UIImage imageNamed:icn];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id key = [self.menuController.screens allKeys][indexPath.row];
    [self.menuController toggleMenuWithScreenID:key];
}


@end
