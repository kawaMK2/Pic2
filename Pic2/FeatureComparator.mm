//
//  FeatureComparison.m
//  Pic2
//
//  Created by 石嶺 眞太郎 on 2017/05/01.
//  Copyright © 2017年 石嶺 眞太郎. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "Pic2-Bridging-Header.h"

@implementation FeatureComparator : NSObject

- (UIImage *)countFeatureQuantities:(UIImage *)image1 :(UIImage *)image2 {
    cv::Mat mat1;
    cv::Mat mat2;
    
    UIImageToMat(image1, mat1);
    UIImageToMat(image2, mat2);
    
    auto detector = cv::ORB::create();
    
    std::vector<cv::KeyPoint> kp1, kp2;
    cv::Mat des1, des2;
    detector->detect(mat1, kp1);
    detector->detect(mat2, kp2);
    
    auto extractor = cv::BRISK::create();
    extractor->compute(mat1, kp1, des1);
    extractor->compute(mat2, kp2, des2);
    
    auto matcher = cv::DescriptorMatcher::create("BruteForce");
    std::vector<cv::DMatch> dmatch;
    matcher->match(des1, des2, dmatch);
    
    
    cv::Mat out;
    cv::drawMatches(mat1, kp1, mat2, kp2, dmatch, out);
    
    return MatToUIImage(out);
}

@end
