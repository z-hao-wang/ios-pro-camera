//
//  CameraRollViewController.swift
//  ProCamera
//
//  Created by Hao Wang on 3/11/15.
//  Copyright (c) 2015 Hao Wang. All rights reserved.
//

import UIKit
import CoreImage

class CameraRollViewController: UIViewController {
    var lastImage: UIImage!
    var lastScale: CGFloat = 1.0
    var tempScale: CGFloat = 1.0

    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func viewWillAppear(animated: Bool) {
        imageView.image = lastImage
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onClose(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }

    @IBAction func didPinch(sender: UIPinchGestureRecognizer) {
        var scale = sender.scale
        tempScale = scale * lastScale
        tempScale = max(tempScale, 1.0)
        tempScale = min(tempScale, 5.0)
        println("pinch \(tempScale)")
        if sender.state == UIGestureRecognizerState.Began {
            
        } else if sender.state == UIGestureRecognizerState.Changed {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.25)
            imageView.transform = CGAffineTransformMakeScale(tempScale, tempScale)
            CATransaction.commit()
        } else if sender.state == UIGestureRecognizerState.Ended {
            lastScale = tempScale
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
