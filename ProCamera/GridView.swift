//
//  GridView.swift
//  ProCamera
//
//  Created by Hao Wang on 3/22/15.
//  Copyright (c) 2015 Hao Wang. All rights reserved.
//

import UIKit

class GridView: UIView {

    let strokeWidth: CGFloat = 1.0
    let mainColorVal: [CGFloat] = [1.0, 1.0, 1.0, 0.7]
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
        let context = UIGraphicsGetCurrentContext()
        CGContextClearRect(context, rect)
        CGContextSetLineWidth(context, strokeWidth)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let color = CGColorCreate(colorSpace, mainColorVal)
        CGContextSetStrokeColorWithColor(context, color)
        //Draw horizontal 2 lines
        CGContextMoveToPoint(context, 0.0, rect.height / 3.0)
        CGContextAddLineToPoint(context, rect.width, rect.height / 3.0)
        CGContextMoveToPoint(context, 0.0, rect.height * 2.0 / 3.0)
        CGContextAddLineToPoint(context, rect.width, rect.height * 2.0 / 3.0)
        
        //Draw vertical 2 lines
        CGContextMoveToPoint(context, rect.width / 3.0, 0.0)
        CGContextAddLineToPoint(context, rect.width / 3.0, rect.height)
        CGContextMoveToPoint(context, rect.width * 2.0 / 3.0, 0.0)
        CGContextAddLineToPoint(context, rect.width * 2.0 / 3.0, rect.height)
        
        CGContextStrokePath(context)
    }


}
