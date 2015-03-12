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
    
    @IBOutlet weak var albumButton: UIImageView!
    @IBOutlet weak var flashBtn: UIButton!
    @IBOutlet weak var controllView: UIView!
    @IBOutlet weak var whiteBalanceSlider: UISlider!
    
    //let sessionQueue = dispatch_queue_create("session_queue", nil)
    
    @IBOutlet weak var previewView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func viewWillAppear(animated: Bool) {
        flashBtn.alpha = 0.3
        super.viewWillAppear(animated)
        super.initialize()
    }
    
    override func postInitilize() {
        super.postInitilize()
        previewView.layer.insertSublayer(super.previewLayer, atIndex: 0)
    }
    
    override func viewDidAppear(animated: Bool) {
        if super.initialized {
            previewLayer.frame = previewView.bounds
            
            //tmp
            setWhiteBalanceMode(.Temperature(5000))
            changeExposureMode(.Custom)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func didPressFlash(sender: UIButton) {
        if flashOn {
            toggleFlashUI(false)
        } else {
            toggleFlashUI(true)
        }
        setFlashMode(!flashOn)
    }
    
    func toggleFlashUI(on: Bool) {
        if on {
            flashBtn.setImage(UIImage(named: "flash"), forState: .Normal)
        } else {
            flashBtn.setImage(UIImage(named: "no-flash"), forState: .Normal)
        }
    }
    
    @IBAction func didMoveShutterSpeed(sender: UISlider) {
        changeExposureDuration(sender.value)
    }
    @IBAction func didMoveWhiteBalance(sender: UISlider) {
        //Todo move this to different
        let value = sender.value
        println(value)
        changeTemperature(value)
    }
    @IBAction func didMoveEV(sender: UISlider) {
        changeEV(sender.value)
    }

    @IBAction func didTouchDownShutter(sender: UIButton) {
        takePhoto()
        beforeSavePhoto()
    }
    
    override func beforeSavePhoto() {
        super.beforeSavePhoto()
        albumButton.image = lastImage
    }

}

