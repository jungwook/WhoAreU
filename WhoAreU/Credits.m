//
//  Credits.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 26..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Credits.h"

#pragma mark Credits

@interface Credits () <UITableViewDelegate, UITableViewDataSource, SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) NSArray *creditStore;
@property (strong, nonatomic) SKProductsRequest *request;
@end

@implementation Credits

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.closeButton.tintColor = [UIColor blackColor];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.activity startAnimating];
    
    id products = @[ @"CREDIT_100", @"CREDIT_250", @"CREDIT_500", @"CREDIT_1000", @"CREDIT_5000", @"CREDIT_10000"];
    self.request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:products]];
    self.request.delegate = self;
    [self.request start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    [self.activity stopAnimating];

    self.creditStore = [self sortedCreditStore:response.products];
    [self.tableView reloadData];
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
    NSLog(@"Count:%ld", self.creditStore.count);
    return self.creditStore.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ProductCell"];
    
    SKProduct* product = [self.creditStore objectAtIndex:indexPath.row];
    
    cell.textLabel.text = product.localizedTitle;
    cell.textLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    cell.textLabel.textColor = [UIColor darkGrayColor];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"$%@", product.price];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    cell.detailTextLabel.textColor = [UIColor blackColor];
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (NSArray*) sortedCreditStore:(NSArray*)products
{
    NSSortDescriptor *lowestPriceToHighest = [NSSortDescriptor sortDescriptorWithKey:@"price" ascending:YES];
    return [products sortedArrayUsingDescriptors:[NSArray arrayWithObject:lowestPriceToHighest]];
}

- (IBAction)closeCreditStore:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)purchaseMyProduct:(SKProduct*)product{
    if ([SKPaymentQueue canMakePayments]) {
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
    else{
        [self alertWithTitle:@"Purchases are disabled in your device" message:nil completion:nil];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(nonnull NSArray<SKPaymentTransaction *> *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"Purchasing");
                break;
            case SKPaymentTransactionStatePurchased: {
                NSLog(@"Purchased ");
                NSUInteger credits = [self creditsForProductId:transaction.payment.productIdentifier];
                
                id title = @"Purchase Successful";
                id message = [NSString stringWithFormat:@"You have bought %ld credits", credits];
                
                [self alertWithTitle:title message:message completion:^(UIAlertAction * _Nonnull action) {
                    [self completePurchase:credits];
                }];
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"Restored ");
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"Purchase failed ");
                break;
            default:
                break;
        }
    }
}

- (void) completePurchase:(NSUInteger)credits
{
    User *me = [User me];
    me.credits += credits;
    [me saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

- (NSUInteger) creditsForProductId:(id)productId
{
    if ([productId isEqualToString:@"CREDIT_100"])
        return 100;
    else if ([productId isEqualToString:@"CREDIT_250"])
        return 250;
    else if ([productId isEqualToString:@"CREDIT_500"])
        return 500;
    else if ([productId isEqualToString:@"CREDIT_1000"])
        return 1000;
    else if ([productId isEqualToString:@"CREDIT_5000"])
        return 5000;
    else if ([productId isEqualToString:@"CREDIT_10000"])
        return 10000;
    else
        return 0;
}

- (void) alertWithTitle:(NSString*)title message:(NSString*)message completion:(void (^)(UIAlertAction * _Nonnull action))action
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:action];
    
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SKProduct *product = [self.creditStore objectAtIndex:indexPath.row];
    [self purchaseMyProduct:product];
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
