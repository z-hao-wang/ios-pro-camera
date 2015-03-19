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
    
    
    
    @IBOutlet weak var exposureDurationSlider: UISlider!
    @IBOutlet weak var exposureValueSlider: UISlider!
    @IBOutlet weak var shutterSpeedLabel: UILabel!
    @IBOutlet weak var isoValueLabel: UILabel!
    @IBOutlet weak var albumButton: UIImageView!
    @IBOutlet weak var flashBtn: UIButton!
    @IBOutlet weak var controllView: UIView!
    @IBOutlet weak var whiteBalanceSlider: UISlider!
    var viewAppeared = false
    var histogramView: UIImageView!
    
    @IBOutlet weak var isoSlider: UISlider!
    
    @IBOutlet weak var evValue: UILabel!
    @IBOutlet weak var takePhotoButton: UIButton!
    //let sessionQueue = dispatch_queue_create("session_queue", nil)
    @IBOutlet weak var innerPhotoButton: UIView!
    
    @IBOutlet weak var previewView: UIView!
    
    @IBOutlet weak var asmButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Make the "take photo" button circular
        takePhotoButton.layer.cornerRadius = (takePhotoButton.bounds.size.height/2)
        innerPhotoButton.layer.cornerRadius = (innerPhotoButton.bounds.size.height/2)
        
        // Make the ASM button have a border and be circular
        asmButton.layer.borderWidth = 2.0
        asmButton.layer.borderColor = UIColor.grayColor().CGColor
        asmButton.layer.cornerRadius = (asmButton.bounds.size.height/2)
        shootMode = 0 //TODO: persist this
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        super.initialize()
    }
    
    override func postInitilize() {
        super.postInitilize()
        if viewAppeared{
            initView()
        }
    }
    
    func initView() {
        previewView.layer.insertSublayer(super.previewLayer, atIndex: 0)
        previewLayer.frame = previewView.bounds
        //tmp
        setWhiteBalanceMode(.Temperature(5000))
        changeExposureMode(AVCaptureExposureMode.AutoExpose)
    }
    
    override func viewDidAppear(animated: Bool) {
        viewAppeared = true
        if super.initialized {
            initView()
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
    
    @IBAction func didPressASM(sender: AnyObject) {
        print("Pressed ASM cycler")
        if ++shootMode! > 2 {
            shootMode = 0
        }
        var buttonTitle = "A"
        switch shootMode {
        case 1:
            buttonTitle = "Tv"
            changeExposureMode(.Custom)
            changeExposureDuration(exposureDurationSlider.value)
            changeEV(exposureValueSlider.value)
            changeExposureDuration(exposureValueSlider.value)
            isoMode = .Auto
        case 2:
            buttonTitle = "M"
            changeExposureMode(.Custom)
            changeExposureDuration(exposureDurationSlider.value)
            isoMode = .Custom
            changeISO(isoSlider.value)
        default:
            buttonTitle = "A"
            changeExposureMode(.AutoExpose)
            currentISOValue = nil
            currentExposureDuration = nil
        }
        asmButton.setTitle(buttonTitle, forState: .Normal)
    }
    
    
    @IBAction func didMoveISO(sender: UISlider) {
        if shootMode == 2 {
            //only works on manual mode
            let value = sender.value
            changeISO(value)
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
    
    override func postCalcHistogram() {
        super.postCalcHistogram()
        if histogramDisplayImage != nil {
            albumButton.image = histogramDisplayImage
        }
    }
    
    override func beforeSavePhoto() {
        super.beforeSavePhoto()
        albumButton.image = lastImage
    }
    
    override func postChangeCameraSetting() {
        super.postChangeCameraSetting()
        //let's calc the denominator
        dispatch_async(dispatch_get_main_queue()) {
            if self.currentExposureDuration != nil {
                 self.shutterSpeedLabel.text = "1/\(self.FloatToDenominator(Float(self.currentExposureDuration!)))"
            } else {
                self.shutterSpeedLabel.text = "Auto"
            }
            if self.currentISOValue != nil {
                self.isoValueLabel.text = "\(Int(self.capISO(self.currentISOValue!)))"
            } else {
                self.isoValueLabel.text = "Auto"
            }
        }
    }

}

