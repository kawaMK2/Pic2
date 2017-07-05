//
//  MonochromeFilter.m
//  Pic2
//
//  Created by 石嶺 眞太郎 on 2017/05/01.
//  Copyright © 2017年 石嶺 眞太郎. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <Foundation/Foundation.h>
#import "Pic2-Bridging-Header.h"

@interface OpenCVUtil : NSObject

/**
 `UIImage`インスタンスをOpenCV画像データに変換するメソッド
 
 @param     image       `UIImage`インスタンス
 @return    `IplImage`インスタンス
 */
+ (IplImage *)IplImageFromUIImage:(UIImage *)image;

/**
 OpenCV画像データを`UIImage`インスタンスに変換するメソッド
 
 @param     image `IplImage`インスタンス
 @return    `UIImage`インスタンス
 */
+ (UIImage *)UIImageFromIplImage:(IplImage*)image;

@end

@implementation MonochromeFilter : NSObject 

+ (UIImage *)doFilter:(UIImage *)image
{
    // CGImageからIplImageを作成
    IplImage *srcImage       = [OpenCVUtil IplImageFromUIImage:image];
    IplImage *grayScaleImage = cvCreateImage(cvGetSize(srcImage), IPL_DEPTH_8U, 1);
    IplImage *dstImage       = cvCreateImage(cvGetSize(srcImage), IPL_DEPTH_8U, 3);
    
    // グレースケール画像に変換
    cvCvtColor(srcImage, grayScaleImage, CV_BGR2GRAY);
    
    // CGImage用にBGRに変換
    cvCvtColor(grayScaleImage, dstImage, CV_GRAY2BGR);
    
    // IplImageからCGImageを作成
    UIImage *effectedImage = [OpenCVUtil UIImageFromIplImage:dstImage];
    
    cvReleaseImage(&srcImage);
    cvReleaseImage(&grayScaleImage);
    cvReleaseImage(&dstImage);
    
    return effectedImage;
}

@end

@implementation OpenCVUtil

+ (IplImage *)IplImageFromUIImage:(UIImage *)image
{
    CGImageRef imageRef = image.CGImage;
    
    // RGB色空間を作成
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 一時的なIplImageを作成
    IplImage *iplimage = cvCreateImage(cvSize(image.size.width,image.size.height), IPL_DEPTH_8U, 4);
    
    // CGBitmapContextをIplImageのビットマップデータのポインタから作成
    CGContextRef contextRef = CGBitmapContextCreate(
                                                    iplimage->imageData,
                                                    iplimage->width,
                                                    iplimage->height,
                                                    iplimage->depth,
                                                    iplimage->widthStep,
                                                    colorSpace,
                                                    kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
    
    // CGImageをCGBitmapContextに描画
    CGContextDrawImage(contextRef,
                       CGRectMake(0, 0, image.size.width, image.size.height),
                       imageRef);
    
    // ビットマップコンテキストと色空間を解放
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    // 最終的なIplImageを作成
    IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
    
    // 一時的なIplImageを解放
    cvCvtColor(iplimage, ret, CV_RGBA2BGR);
    cvReleaseImage(&iplimage);
    
    return ret;
}

+ (UIImage *)UIImageFromIplImage:(IplImage*)image
{
    CGColorSpaceRef colorSpace;
    if (image->nChannels == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        //BGRになっているのでRGBに変換
        cvCvtColor(image, image, CV_BGR2RGB);
    }
    
    // IplImageのビットマップデータのポインタアドレスからNSDataを作成
    NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // CGImageを作成
    CGImageRef imageRef = CGImageCreate(image->width,
                                        image->height,
                                        image->depth,
                                        image->depth * image->nChannels,
                                        image->widthStep,
                                        colorSpace,
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                        provider,
                                        NULL,
                                        false,
                                        kCGRenderingIntentDefault
                                        );
    
    // UIImageを生成
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return ret;
}

@end
