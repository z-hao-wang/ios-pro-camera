//
//  MeterView.swift
//  ProCamera
//
//  Created by Hao Wang on 3/21/15.
//  Copyright (c) 2015 Hao Wang. All rights reserved.
//

import UIKit

class MeterView: UIView {

    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        println("MeterView: drawRect \(rect)")
        let context = UIGraphicsGetCurrentContext()
        CGContextClearRect(context, rect)
        let strokeWidth: CGFloat = 1.0
        CGContextSetLineWidth(context, strokeWidth)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let components: [CGFloat] = [1.0, 1.0, 1.0, 0.8]
        let color = CGColorCreate(colorSpace, components)
        CGContextSetStrokeColorWithColor(context, color)
        //find max_pixels in histogramRaw
        let meterMarkCount = 20
        let halfHeight = rect.height / 2.0
        // Draw meter from quater height. Leave top and bottom quater height
        // Meter only takes half of total height
        for var i = 1; i < meterMarkCount; i++ {
            let y = CGFloat(i) * halfHeight / CGFloat(meterMarkCount) + halfHeight / 2.0
            CGContextMoveToPoint(context, 0, y) //x = i, y = height
            CGContextAddLineToPoint(context, rect.width, y)
        }
        CGContextStrokePath(context)
    }


}
