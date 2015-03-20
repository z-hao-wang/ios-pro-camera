//
//  PreviewView.swift
//  ProCamera
//
//  Created by Hao Wang on 3/19/15.
//  Copyright (c) 2015 Hao Wang. All rights reserved.
//

import UIKit

class PreviewView: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    override func drawRect(rect: CGRect) {
        //let context = UIGraphicsGetCurrentContext()
        //CGContextSetLineWidth(context, 4.0);
        //CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor);
        //CGContextFillRect(context, CGRect(x: 0.0, y: 0.0, width: 2.0, height: 10.0));
        //let histogramImage = UIGraphicsGetImageFromCurrentImageContext()
        let context = UIGraphicsGetCurrentContext()
        CGContextSetLineWidth(context, 4.0)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let components: [CGFloat] = [0.0, 0.0, 1.0, 1.0]
        let color = CGColorCreate(colorSpace, components)
        CGContextSetStrokeColorWithColor(context, color)
        CGContextMoveToPoint(context, 30, 30)
        CGContextAddLineToPoint(context, 300, 400)
        CGContextStrokePath(context)
    }

}
