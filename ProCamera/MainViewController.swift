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
import QuartzCore


class MainViewController: AVCoreViewController {
    
    
    private let whiteBalanceModes = ["Auto", "Sunny", "Cloudy", "Manual"]
    @IBOutlet weak var exposureDurationSlider: UISlider!
    @IBOutlet weak var exposureValueSlider: UISlider!
    @IBOutlet weak var shutterSpeedLabel: UILabel!
    @IBOutlet weak var isoValueLabel: UILabel!
    @IBOutlet weak var albumButton: UIImageView!
    @IBOutlet weak var flashBtn: UIButton!
    @IBOutlet weak var controllView: UIView!
    @IBOutlet weak var whiteBalanceSlider: UISlider!
    
    @IBOutlet weak var takePhotoButton: UIButton!
    //let sessionQueue = dispatch_queue_create("session_queue", nil)
    @IBOutlet weak var innerPhotoButton: UIView!
    
    @IBOutlet weak var previewView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        takePhotoButton.layer.cornerRadius = (takePhotoButton.bounds.size.height/2);
        innerPhotoButton.layer.cornerRadius = (innerPhotoButton.bounds.size.height/2);
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
            changeExposureDuration(exposureDurationSlider.value)
            changeEV(exposureValueSlider.value)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPressTakePhoto(sender: AnyObject) {
        takePhoto()
        beforeSavePhoto()
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
    
    override func beforeSavePhoto() {
        super.beforeSavePhoto()
        albumButton.image = lastImage
    }
    
    override func postChangeCameraSetting() {
        super.postChangeCameraSetting()
        //let's calc the denominator
        dispatch_async(dispatch_get_main_queue()) {
            self.shutterSpeedLabel.text = "1/\(self.FloatToDenominator(Float(self.currentExposureDuration!)))"
            self.isoValueLabel.text = "\(self.currentISOValue!)"
        }
        println("post change postChangeCameraSetting")
    }

}

