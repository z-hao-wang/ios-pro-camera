//
//  ViewController.swift
//  ProCamera
//
//  Created by Hao Wang on 3/8/15.
//  Copyright (c) 2015 Hao Wang. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary



class MainViewController: AVCoreViewController {
    
    
    private let whiteBalanceModes = ["Auto", "Sunny", "Cloudy", "Manual"]
    
    @IBOutlet weak var controllView: UIView!
    @IBOutlet weak var whiteBalanceSlider: UISlider!
    
    //let sessionQueue = dispatch_queue_create("session_queue", nil)
    
    @IBOutlet weak var previewView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func postInitilize() {
        super.postInitilize()
        previewView.layer.insertSublayer(previewLayer, atIndex: 0)
    }
    
    override func viewDidAppear(animated: Bool) {
        if initialized {
            previewLayer.frame = previewView.bounds
            
            //tmp
            setWhiteBalanceMode(.Temperature(5000))
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    @IBAction func didMoveWhiteBalance(sender: UISlider) {
        //Todo move this to different
        let value = sender.value
        println(value)
        changeTemperature(value)
    }
    
    

    @IBAction func didPressShutter(sender: AnyObject) {
        takePhoto()
    }

}

