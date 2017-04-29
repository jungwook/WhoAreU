//
//  Credits.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 26..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Credits.h"

#pragma mark Credits

@interface Credits () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) NSArray *creditStore;
@end

@implementation Credits

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.creditStore = @[
        @{ @"credits" : @(100), @"price" : @(0.99)},
        @{ @"credits" : @(250), @"price" : @(1.99)},
        @{ @"credits" : @(500), @"price" : @(3.99)},
        @{ @"credits" : @(1000), @"price" : @(5.99)},
        @{ @"credits" : @(5000), @"price" : @(9.99)},
        @{ @"credits" : @(10000), @"price" : @(19.99)},
                         ];
    
    self.closeButton.tintColor = [UIColor blackColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.creditStore.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ProductCell"];
    
    id product = [self.creditStore objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [[NSNumberFormatter localizedStringFromNumber:product[@"credits"] numberStyle:NSNumberFormatterDecimalStyle] stringByAppendingString:@" credits"];
    cell.textLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    cell.textLabel.textColor = [UIColor darkGrayColor];
    cell.detailTextLabel.text = [@"$" stringByAppendingString:[product[@"price"] stringValue]];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    cell.detailTextLabel.textColor = [UIColor blackColor];
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (IBAction)closeCreditStore:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    __LF
    id product = [self.creditStore objectAtIndex:indexPath.row];
    NSUInteger credits = [product[@"credits"] integerValue];
    
    NSString *message = [NSString stringWithFormat:@"Do you want to buy %@ for $%@",[[NSNumberFormatter localizedStringFromNumber:product[@"credits"] numberStyle:NSNumberFormatterDecimalStyle] stringByAppendingString:@" credits"], [@"$" stringByAppendingString:[product[@"price"] stringValue]]];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirm Your In-App Purchase" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        Installation *install = [Installation currentInstallation];
        install.credits += credits;
        [install saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alert addAction:ok];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
