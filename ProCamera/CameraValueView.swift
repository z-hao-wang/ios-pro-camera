//
//  CameraValueView.swift
//  ProCamera
//
//  Created by Brian Jordan on 3/18/15.
//  Copyright (c) 2015 Hao Wang. All rights reserved.
//

import UIKit

class CameraValueView: UIView {
    @IBOutlet var contentView: UIView!

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    func initSubviews() {
        // standard initialization logic
        let nib = UINib(nibName: "CameraValueView", bundle: nil)
        nib.instantiateWithOwner(self, options: nil)
        contentView.frame = bounds
        addSubview(contentView)
        
        // custom initialization logic
        

    }
}
