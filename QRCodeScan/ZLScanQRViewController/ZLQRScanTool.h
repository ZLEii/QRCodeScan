//
//  ZLQRScanTool.h
//  QRCodeScan
//
//  Created by 张磊 on 16/6/23.
//  Copyright © 2016年 lei. All rights reserved.
//
/**
 这个类主要是从字符串生成二维码，以及把二维码图片变成字符串
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ZLQRScanTool : NSObject

/**
 *   从图片读取二维码
 *
 *  @param qrImage 图片
 *
 *  @return 字符串
 */
+ (NSString *)qrFromPhoto:(UIImage *)qrImage;

/**
 *  把字符串变成二维码图片
 *
 *  @param QRvalue 字符串
 *
 *  @return 图片
 */
+ (UIImage *)createQrImageWithString:(NSString *)string;

/**
 *  把NSData变成二维码图片
 *
 *  @param data NSData
 *
 *  @return 图片
 */
+ (UIImage *)createQrImageWithData:(NSData *)data;

/**
 * 根据CIImage生成指定大小的UIImage
 *
 * @param image CIImage
 * @param size 图片宽度
 */
+ (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat)size;
@end
