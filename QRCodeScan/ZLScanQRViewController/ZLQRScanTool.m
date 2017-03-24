//
//  ZLQRScanTool.m
//  QRCodeScan
//
//  Created by 张磊 on 16/6/23.
//  Copyright © 2016年 lei. All rights reserved.
//

#import "ZLQRScanTool.h"


@implementation ZLQRScanTool

+ (NSString *)qrFromPhoto:(UIImage *)qrImage {
    // detector:检测器,类型为二维码
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:qrImage.CGImage]];
    if (features.count == 0) {
        return nil;
    }
    // 取出第一个二维码,
    return ((CIQRCodeFeature *)features.firstObject).messageString;
}

//生成二维码图片
+ (UIImage *)createQrImageWithString:(NSString *)string {
    // 3.将字符串转成NSData
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [ZLQRScanTool createQrImageWithData:data];
}

+ (UIImage *)createQrImageWithData:(NSData *)data {
    // 1. 实例化二维码滤镜
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    // 2.恢复滤镜的默认属性(因为滤镜有坑保存上一次的属性)
    [filter setDefaults];

    // 4.通过KVO设置滤镜,传入data,将来滤镜就知道要通过传入的数据生成二维码
    [filter setValue:data forKey:@"inputMessage"];
    
    // 5.生成二维码
    CIImage *outputImage = [filter outputImage];
    
    //    UIImage *image = [UIImage imageWithCIImage:outputImage];
    return [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:[UIScreen mainScreen].bounds.size.width];

}

/**
 * 根据CIImage生成指定大小的UIImage
 *
 * @param image CIImage
 * @param size 图片宽度
 */
+ (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat)size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}
@end
