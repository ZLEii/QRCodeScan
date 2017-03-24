//
//  MyQRCodeViewController.m
//  QRCodeScan
//
//  Created by 张磊 on 16/6/23.
//  Copyright © 2016年 lei. All rights reserved.
//

#import "MyQRCodeViewController.h"
#import "ZLQRScanTool.h"

@interface MyQRCodeViewController ()

@end

@implementation MyQRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.851 alpha:1.000];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(50, 100, self.view.bounds.size.width - 100, self.view.bounds.size.width - 100)];
    imgView.image = self.image;
    [self.view addSubview:imgView];
    
    CGFloat h = 150.0;
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - h, self.view.bounds.size.width, h)];
    textView.font = [UIFont systemFontOfSize:20];
    [self.view addSubview:textView];
    NSString *text = [ZLQRScanTool qrFromPhoto:self.image];
    textView.text = text;
    textView.editable = NO;
    [self setupNavigationItem];
}

- (void)setupNavigationItem {
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"保存到相册" style:UIBarButtonItemStylePlain target:self action:@selector(clickRightItem)];
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)clickRightItem {
    UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *msg = error ? @"保存到相册失败" : @"保存到相册成功";
    UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:msg message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alertCtr addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertCtr animated:YES completion:nil];
}
@end
