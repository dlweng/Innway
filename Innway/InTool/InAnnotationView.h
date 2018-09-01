//
//  InAnnotationView.h
//  Innway
//
//  Created by danly on 2018/9/2.
//  Copyright © 2018年 innwaytech. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface InAnnotation : NSObject <MKAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy, nullable) NSString *title;

@end



@interface InAnnotationView : MKAnnotationView
@end
