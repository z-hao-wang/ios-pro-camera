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
            let mainColorVal: [CGFloat] = [1.0, 1.0, 1.0, 0.8]
            let bgColorVal: [CGFloat] = [0.0, 0.0, 0.0, 0.2]
            let bgColor = CGColorCreate(colorSpace, bgColorVal)
            let color = CGColorCreate(colorSpace, mainColorVal)
            CGContextSetStrokeColorWithColor(context, color)
            //find max_pixels in histogramRaw
            var max_pixels = histogramRaw[0]
            for var i = 1; i < histogramRaw.count; i++ {
                if histogramRaw[i] > max_pixels {
                    max_pixels = histogramRaw[i]
                }
            }
            
            //draw BG
            CGContextSetLineWidth(context, strokeWidth + 2.0)
            CGContextSetStrokeColorWithColor(context, bgColor)
            //map max_pixels to rect.height
            // height = x / max_pixels * rect.height
            for var i = 0; i < histogramRaw.count; i++ {
                var value_height = CGFloat(histogramRaw[i]) / CGFloat(max_pixels) * CGFloat(rect.height)
                if value_height < 1.0 {
                    value_height = 1.0 //min height = 1.0
                }
                CGContextMoveToPoint(context, CGFloat(i) * strokeWidth + strokeWidth / 2.0 , rect.height) //x = i, y = height
                CGContextAddLineToPoint(context, CGFloat(i) * strokeWidth + strokeWidth / 2.0, rect.height - value_height - 2.0) //x = i, y = height - value_height
            }
            CGContextStrokePath(context)
            //Draw bar
            CGContextSetLineWidth(context, strokeWidth - 2.0)
            CGContextSetStrokeColorWithColor(context, color)

            for var i = 0; i < histogramRaw.count; i++ {
                var value_height = CGFloat(histogramRaw[i]) / CGFloat(max_pixels) * CGFloat(rect.height)
                if value_height < 1.0 {
                    value_height = 1.0 //min height = 1.0
                }
                CGContextMoveToPoint(context, CGFloat(i) * strokeWidth + strokeWidth / 2.0, rect.height - 2.0) //x = i, y = height
                var heightTo = rect.height - value_height
                if heightTo <= 2.0 {
                    heightTo = 2.0
                }
                CGContextAddLineToPoint(context, CGFloat(i) * strokeWidth + strokeWidth / 2.0, heightTo) //x = i, y = height - value_height
            }
            CGContextStrokePath(context)
        }
    }
    
    func didUpdateHistogramRaw(data: [Int]) {
        histogramRaw = data
        
        self.setNeedsDisplay()
    }
}
