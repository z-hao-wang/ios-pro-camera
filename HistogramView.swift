//
//  HistogramView.swift
//  ProCamera
//
//  Created by Hao Wang on 3/19/15.
//  Copyright (c) 2015 Hao Wang. All rights reserved.
//

import UIKit

class HistogramView: UIView {
    
    var histogramRaw: [Int]!
    var strokeWidth: CGFloat = 8.0

    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        if histogramRaw != nil {
            let context = UIGraphicsGetCurrentContext()
            CGContextClearRect(context, rect)
            CGContextSetLineWidth(context, strokeWidth - 2.0)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let components: [CGFloat] = [1.0, 1.0, 1.0, 1.0]
            let color = CGColorCreate(colorSpace, components)
            CGContextSetStrokeColorWithColor(context, color)
            //find max_pixels in histogramRaw
            var max_pixels = histogramRaw[0]
            for var i = 1; i < histogramRaw.count; i++ {
                if histogramRaw[i] > max_pixels {
                    max_pixels = histogramRaw[i]
                }
            }
            //map max_pixels to rect.height
            // height = x / max_pixels * rect.height
            for var i = 0; i < histogramRaw.count; i++ {
                var value_height = CGFloat(histogramRaw[i]) / CGFloat(max_pixels) * CGFloat(rect.height)
                if value_height < 1.0 {
                    value_height = 1.0 //min height = 1.0
                }
                CGContextMoveToPoint(context, CGFloat(i) * strokeWidth + strokeWidth / 2.0, rect.height) //x = i, y = height
                CGContextAddLineToPoint(context, CGFloat(i) * strokeWidth + strokeWidth / 2.0, rect.height - value_height) //x = i, y = height - value_height
            }
            CGContextStrokePath(context)
        }
    }
    
    func didUpdateHistogramRaw(data: [Int]) {
        histogramRaw = data
        
        self.setNeedsDisplay()
    }
}
