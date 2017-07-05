//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FeatureComparator : NSObject

- (UIImage *)countFeatureQuantities :(UIImage*)image1 :(UIImage *)originalImage;

@end

@interface MonochromeFilter : NSObject

+ (UIImage *)doFilter:(UIImage *)image;

@end


