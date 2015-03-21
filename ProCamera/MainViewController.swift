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


class MainViewController: AVCoreViewController, UIScrollViewDelegate {
    
    
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var histogramView: HistogramView!
    
    @IBOutlet weak var meterCenter: UIView!
    @IBOutlet weak var meterView: MeterView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var exposureDurationSlider: UISlider!
    @IBOutlet weak var exposureValueSlider: UISlider!
    @IBOutlet weak var shutterSpeedLabel: UILabel!
    @IBOutlet weak var isoValueLabel: UILabel!
    @IBOutlet weak var albumButton: UIImageView!
    @IBOutlet weak var flashBtn: UIButton!
    @IBOutlet weak var controllView: UIView!
    @IBOutlet weak var whiteBalanceSlider: UISlider!
    var viewAppeared = false
    
    @IBOutlet weak var isoSlider: UISlider!
    
    @IBOutlet weak var evValue: UILabel!
    @IBOutlet weak var takePhotoButton: UIButton!
    //let sessionQueue = dispatch_queue_create("session_queue", nil)
    @IBOutlet weak var innerPhotoButton: UIView!
    
    @IBOutlet weak var previewView: UIView!
    var currentSetAttr: String! //The current attr to change

    
    @IBOutlet weak var asmButton: UIButton!
    let enabledLabelColor = UIColor.yellowColor()
    let disabledLabelColor = UIColor.whiteColor()
    
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
        histogramView.opaque = false
        histogramView.backgroundColor = UIColor.clearColor()
        scrollView.delegate = self
    }
    
    override func postInitilize() {
        super.postInitilize()
        if viewAppeared{
            initView()
        }
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.LandscapeLeft.rawValue)
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    func initView() {
        previewView.layer.insertSublayer(super.previewLayer, atIndex: 0)
        previewLayer.frame = previewView.bounds
        //tmp
        setWhiteBalanceMode(.Temperature(5000))
        changeExposureMode(AVCaptureExposureMode.AutoExpose)
        updateASM()
        
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
    
    @IBAction func didTapAlbumButton(sender: UIButton) {
        self.performSegueWithIdentifier("cameraRollSegue", sender: self)
    }
    
    @IBAction func didPressTakePhoto(sender: AnyObject) {
        takePhoto()
        beforeSavePhoto()
    }
    
    func toggleISO(enabled: Bool) {
        if enabled {
            isoValueLabel.textColor = enabledLabelColor
            isoSlider.hidden = false
        } else {
            isoValueLabel.textColor = disabledLabelColor
            isoSlider.hidden = true
        }
    }
    
    func toggleExposureDuration(enabled: Bool) {
        if enabled {
            shutterSpeedLabel.textColor = enabledLabelColor
            exposureDurationSlider.hidden = false
        } else {
            shutterSpeedLabel.textColor = disabledLabelColor
            exposureDurationSlider.hidden = true
        }
    }
    
    func toggleExposureValue(enabled: Bool) {
        if enabled {
            evValue.textColor = enabledLabelColor
            exposureValueSlider.hidden = false
        } else {
            evValue.textColor = disabledLabelColor
            exposureValueSlider.hidden = true
        }
    }
    
    func toggleWhiteBalance(enabled: Bool) {
        if enabled {
            whiteBalanceSlider.hidden = false
        } else {
            whiteBalanceSlider.hidden = true
        }
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
    
    func updateASM() {
        var buttonTitle = "A"
        switch shootMode {
        case 1:
            buttonTitle = "Tv"
            changeExposureMode(.Custom)
            changeExposureDuration(exposureDurationSlider.value)
            changeEV(exposureValueSlider.value)
            changeExposureDuration(exposureValueSlider.value)
            isoMode = .Auto
            toggleISO(false)
            toggleExposureDuration(true)
            toggleExposureValue(true)
        case 2:
            buttonTitle = "M"
            changeExposureMode(.Custom)
            changeExposureDuration(exposureDurationSlider.value)
            isoMode = .Custom
            changeISO(isoSlider.value)
            toggleISO(true)
            toggleExposureDuration(true)
            toggleExposureValue(false)
        default:
            buttonTitle = "A"
            changeExposureMode(.AutoExpose)
            currentISOValue = nil
            currentExposureDuration = nil
            toggleISO(false)
            toggleExposureDuration(false)
            toggleExposureValue(false)
        }
        asmButton.setTitle(buttonTitle, forState: .Normal)
    }
    
    @IBAction func didPressASM(sender: AnyObject) {
        print("Pressed ASM cycler")
        scrollView.hidden = true
        if ++shootMode! > 2 {
            shootMode = 0
        }
        updateASM()
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
    
    @IBAction func didPressEvButton(sender: UIButton) {
        println("Pressed EV")
        if shootMode == 1 {
            self.currentSetAttr = "EV"
            initMeterView()
        }
    }
    
    @IBAction func didPressIsoButton(sender: UIButton) {
        println("Pressed ISO")
        if shootMode == 2 {
            self.currentSetAttr = "ISO"
            initMeterView()
        }
    }
    
    @IBAction func didPressShutterButton(sender: UIButton) {
        println("Pressed Shutter")
        if shootMode == 1 || shootMode == 2 {
            self.currentSetAttr = "SS"
            initMeterView()
        }
    }
    
    @IBAction func didPressWBButton(sender: UIButton) {
        println("Pressed WB")
    }
    
    func initMeterView() {
        scrollView.hidden = false
        meterCenter.hidden = false
        //important for scroll view to work properly
        scrollView.contentSize = meterView.frame.size
        let value = getCurrentValueNormalized(currentSetAttr)
        println(value)
        let scrollMax = scrollView.contentSize.height -
            scrollView.frame.height
        scrollView.contentOffset.y = CGFloat(value) * scrollMax
    }
    
    func destroyMeterView() {
        scrollView.hidden = true
        meterCenter.hidden = true
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let scrollMax = scrollView.contentSize.height -
            scrollView.frame.height
        var scrollOffset = scrollView.contentOffset.y
        if scrollOffset < 0 {
            scrollOffset = 0
        } else if scrollOffset > scrollMax {
            scrollOffset = scrollMax
        }
        let value = Float(scrollOffset / scrollMax)
        switch currentSetAttr {
            case "EV":
                changeEV(value)
            case "ISO":
                changeISO(value)
            case "SS":
                changeExposureDuration(value)
            default:
                let x = 1
        }
    }
    
    override func postCalcHistogram() {
        super.postCalcHistogram()
        histogramView.didUpdateHistogramRaw(histogramRaw)
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
            
            if self.shootMode == 1 { //only in TV mode
                //map 0 - EV_MAX, to -3 - 3
                // self.exposureValue / EV_MAX = x / 6.0
                // x -= 3.0
                let expoVal = self.exposureValue / self.EV_max * 6.0 - 3.0
                self.evValue.text = expoVal.format(".1") //1 digit
            } else {
                self.evValue.text = "Auto"
            }
        }
    }
    
    /*
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("barCell", forIndexPath: indexPath) as ControllCollectionViewCell
        if currentSetAttr != nil {
            switch currentSetAttr {
            case "EV":
                cell.valueLabel.text = String(indexPath.row)
            case "ISO":
                cell.valueLabel.text = String(indexPath.row)
            case "SS":
                cell.valueLabel.text = String(indexPath.row)
            default:
                cell.valueLabel.text = String(indexPath.row)
            }
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 25
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.hidden = true //hide the view
    }
    */

    @IBAction func onTapPreview(sender: UITapGestureRecognizer) {
        destroyMeterView()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "cameraRollSegue" {
            let vcNav = segue.destinationViewController as? UINavigationController
            if vcNav != nil {
                let vc = vcNav!.viewControllers[0] as? CameraRollViewController
                if vc != nil {
                    vc!.lastImage = self.lastImage
                }
            }
            
        }
    }
}

