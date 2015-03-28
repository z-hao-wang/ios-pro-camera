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
    @IBOutlet weak var gridView: GridView!
    @IBOutlet weak var shutterSpeedLabel: UILabel!
    @IBOutlet weak var isoValueLabel: UILabel!
    @IBOutlet weak var albumButton: UIImageView!
    
    // Containers. For rotation purpose
    @IBOutlet weak var evContainer: UIView!
    @IBOutlet weak var isoContainer: UIView!
    @IBOutlet weak var shutterContainer: UIView!
    @IBOutlet weak var wbContainer: UIView!
    
    var viewAppeared = false
    
    @IBOutlet weak var meterImage: UIImageView!
    
    @IBOutlet weak var evValue: UILabel!
    @IBOutlet weak var takePhotoButton: UIButton!
    //let sessionQueue = dispatch_queue_create("session_queue", nil)
    @IBOutlet weak var innerPhotoButton: UIView!
    
    @IBOutlet weak var previewView: UIView!
    var currentSetAttr: String! //The current attr to change

    
    @IBOutlet weak var asmButton: UIButton!
    let enabledLabelColor = UIColor.whiteColor()
    let disabledLabelColor = UIColor.grayColor()
    let currentlyEditedLabelColor = UIColor.yellowColor()
    
    // Setting buttons
    @IBOutlet weak var wbButton: UIButton!
    @IBOutlet weak var shutterButton: UIButton!
    @IBOutlet weak var isoButton: UIButton!
    @IBOutlet weak var evButton: UIButton!
    
    @IBOutlet weak var wbIconButton: UIButton!
    
    var viewDidAppeared: Bool = false
    var gridEnabled: Bool = false
    
    var scrollViewInitialX: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let settingsValueTmp = NSUserDefaults.standardUserDefaults().objectForKey("settingsStore") as? [String: Bool]
        settingsUpdated(settingsValueTmp)
        //Listen to notif
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "settingsUpdatedObserver:", name: "settingsUpdatedNotification", object: nil)
        
        // Make the "take photo" button circular
        takePhotoButton.layer.cornerRadius = (takePhotoButton.bounds.size.height/2)
        innerPhotoButton.layer.cornerRadius = (innerPhotoButton.bounds.size.height/2)
        
        // Make the ASM button have a border and be circular
        asmButton.layer.borderWidth = 2.0
        asmButton.layer.borderColor = UIColor.grayColor().CGColor
        asmButton.layer.cornerRadius = (asmButton.bounds.size.height/2)
        shootMode = 0 //TODO: persist this
        
        // Handle swiping on scroll view to hide
        var recognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "scrollSwipedRight")
        self.scrollView.addGestureRecognizer(recognizer)
        recognizer.direction = UISwipeGestureRecognizerDirection.Right;
        self.scrollView.delaysContentTouches = true
        
        let buttonTypesForGestures = [
            "didSwipeWbButton": wbButton,
            "didSwipeEvButton": evButton,
            "didSwipeIsoButton": isoButton,
            "didSwipeShutterButton": shutterButton
        ]
        
        for (action, button) in buttonTypesForGestures {
            var newRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: Selector(action))
            newRecognizer.direction = UISwipeGestureRecognizerDirection.Left;
            button.addGestureRecognizer(newRecognizer)
        }
        
        updateASM()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didDeviceRotateAnimated", name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    func didDeviceRotateAnimated() {
        didDeviceRotate(animated: true)
    }
    
    func didDeviceRotate(animated: Bool = true) {
        let orientation = UIDevice.currentDevice().orientation
        let menuWidth: CGFloat = 90.0 //Main menu bar width/height = 90pt
        //println(histogramView.frame)
        //For histogram width and height. rotation will swap it's dimension
        var width = histogramView.frame.width
        var height = histogramView.frame.height
        if height > width {
            width = histogramView.frame.height
            height = histogramView.frame.width
        }
        //histogramView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        if orientation == .Portrait || orientation == .PortraitUpsideDown {
            //portrait
            setTextRotation(90.0)
            //bottom left
            //previewView height = 320pt
            setHistogramCenter(height / 2.0 + 10.0, y: previewView.frame.height - width / 2.0 - 10.0, animated: animated)
            //Strange rotatoin is going on
        } else if orientation == .LandscapeLeft {
            //Landscape
            setTextRotation(180.0)
            setHistogramCenter(width / 2.0 + 10.0, y: previewView.frame.height - height / 2.0 - 10.0, animated: animated)
        } else if orientation == .LandscapeRight {
            setTextRotation(0.0)
            setHistogramCenter(width / 2.0 + 10.0, y: previewView.frame.height - height / 2.0 - 10.0, animated: animated)
        } else {
            println("unknown orientation \(orientation)")
            //set histogram initial state
            self.histogramView.transform = CGAffineTransformIdentity
            setHistogramCenter(width / 2.0 + 10.0, y: previewView.frame.height - height / 2.0 - 10.0, animated: animated)
        }
    }
    
    func setTextRotation(rotation: CGFloat) {
        let transform = CGAffineTransformMakeRotation(rotation * CGFloat(M_PI) / 180.0)
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.asmButton.transform = transform
            self.evContainer.transform = transform
            self.isoContainer.transform = transform
            self.shutterContainer.transform = transform
            self.wbContainer.transform = transform
            self.histogramView.transform = transform
        })
    }
    
    func setHistogramCenter(x: CGFloat, y: CGFloat, animated: Bool) {
        if animated {
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.histogramView.center.y = y
                self.histogramView.center.x = x
            })
        } else {
            self.histogramView.center.y = y
            self.histogramView.center.x = x
        }
        
        println("histogram new center= \(x), \(y)")
    }
    
    func showHistogramView() {
        histogramView.hidden = false
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func settingsUpdated(settingsVal: [String: Bool]!) {
        if settingsVal != nil && settingsVal!["Grid"] != nil {
            gridEnabled = settingsVal["Grid"]!
            if gridEnabled {
                //Set BG color to none
                gridView.opaque = false
                gridView.backgroundColor = UIColor.clearColor()
            }
            gridView.hidden = !gridEnabled
        }
    }
    
    func settingsUpdatedObserver(notification: NSNotification) {
        let settingsVal = notification.userInfo as? [String: Bool]
        settingsUpdated(settingsVal)
    }
    
    func scrollSwipedRight() {
        println("Scroll swiped right")
        destroyMeterView()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        super.initialize()
        histogramView.opaque = false
        histogramView.backgroundColor = UIColor.clearColor()
        scrollView.delegate = self
        println("viewWilAppear")
    }
    
    override func viewWillDisappear(animated: Bool) {
        histogramView.hidden = true
        println("viewWillDisappear")
    }
    
    override func viewWillLayoutSubviews() {
        println("viewWillLayoutSubviews")
        if viewDidAppeared {
            didDeviceRotate(animated: false)
            histogramView.hidden = false
            println("set didDeviceRotate")
        }
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
        
        viewDidAppeared = true
        //NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "showHistogramView", userInfo: nil, repeats: false)
        println("view did appear")
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
    @IBAction func didZoom(sender: UIPinchGestureRecognizer) {
        var scale = sender.scale
        
        //TODO: Detect all touches are in preview layer
        if sender.state == UIGestureRecognizerState.Began {
            
        } else if sender.state == UIGestureRecognizerState.Changed {
            zoomVideoOutput(scale)
        } else if sender.state == UIGestureRecognizerState.Ended {
            currentScale = tempScale
        }
        
    }
    
    func toggleISO(enabled: Bool) {
        if enabled {
            isoValueLabel.textColor = enabledLabelColor
        } else {
            isoValueLabel.textColor = disabledLabelColor
        }
    }
    
    func toggleExposureDuration(enabled: Bool) {
        if enabled {
            shutterSpeedLabel.textColor = enabledLabelColor
        } else {
            shutterSpeedLabel.textColor = disabledLabelColor
        }
    }
    
    func toggleExposureValue(enabled: Bool) {
        if enabled {
            evValue.textColor = enabledLabelColor
        } else {
            evValue.textColor = disabledLabelColor
        }
    }
    
    
    func updateASM() {
        var buttonTitle = "A"
        switch shootMode {
        case 1:
            buttonTitle = "Tv"
            changeExposureMode(.Custom)
            changeExposureDuration(getCurrentValueNormalized("SS"))
            changeEV(getCurrentValueNormalized("EV"))
            isoMode = .Auto
            toggleISO(false)
            toggleExposureDuration(true)
            toggleExposureValue(true)
        case 2:
            buttonTitle = "M"
            changeExposureMode(.Custom)
            changeExposureDuration(getCurrentValueNormalized("SS"))
            isoMode = .Custom
            changeISO(getCurrentValueNormalized("ISO"))
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
        changeTemperature(getCurrentValueNormalized("WB"))
        asmButton.setTitle(buttonTitle, forState: .Normal)
    }
    
    @IBAction func didPressASM(sender: AnyObject) {
        print("Pressed ASM cycler")
        scrollView.hidden = true
        if ++shootMode! > 2 {
            shootMode = 0
        }
        updateASM()
        destroyMeterView()
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
    
    func didSwipeEvButton() {
        activateEvControl()
    }
    
    @IBAction func didPressEvButton(sender: UIButton) {
        activateEvControl()
    }
    
    func activateEvControl() {
        if shootMode == 1 {
            onPressedControl("EV")
        }
    }
    
    func didSwipeIsoButton() {
        activateIsoControl()
    }
    
    @IBAction func didPressIsoButton(sender: UIButton) {
        println("Pressed ISO")
        activateIsoControl()
    }
    
    func activateIsoControl() {
        if shootMode == 2 {
            onPressedControl("ISO")
        }
    }
    
    func didSwipeShutterButton() {
        activateShutterControl()
    }
    
    @IBAction func didPressShutterButton(sender: UIButton) {
        println("Pressed Shutter")
        activateShutterControl()
    }
    
    func activateShutterControl() {
        if shootMode == 1 || shootMode == 2 {
            onPressedControl("SS")
        }
    }
    
    func didSwipeWbButton() {
        activateWbControl()
    }
    
    @IBAction func didPressWBButton(sender: UIButton) {
        println("Pressed WB")
        activateWbControl()
    }
    
    func activateWbControl() {
        println("Toggling wb")
        onPressedControl("WB")
    }
    
    func updateHighlight() {
        switch currentSetAttr {
            case "ISO":
                isoValueLabel.textColor = currentlyEditedLabelColor
            case "SS":
                shutterSpeedLabel.textColor = currentlyEditedLabelColor
            case "EV":
                evValue.textColor = currentlyEditedLabelColor
        default:
            wbIconButton.setImage(UIImage(named: "wb_sunny_yellow"), forState: UIControlState.Normal)
        }
        
    }
    
    func onPressedControl(controlName: String) {
        if (scrollView.hidden) {
            self.currentSetAttr = controlName
            openMeterView()
        } else {
            if (controlName == currentSetAttr) {
                destroyMeterView()
            } else {
                closeMeterView({
                    self.currentSetAttr = controlName
                    self.openMeterView()
                })
            }
        }
    }
    
    func toggleMeterView() {
        if (scrollView.hidden) {
            openMeterView()
        } else {
            destroyMeterView()
        }
    }
    
    func openMeterView() {
        initMeterView()
        updateHighlight()
    }
    
    func initMeterView() {
        let scrollViewAlpha: CGFloat = 0.6
        scrollView.hidden = false
        //kill scrolling if any
        let offset = scrollView.contentOffset
        scrollView.setContentOffset(offset, animated: false)
        meterCenter.hidden = false
        //important for scroll view to work properly
        scrollView.contentSize = meterView.frame.size
        let value = getCurrentValueNormalized(currentSetAttr)
        println(value)
        let scrollMax = scrollView.contentSize.height -
            scrollView.frame.height
        scrollView.contentOffset.y = CGFloat(value) * scrollMax
        
        //Changing scrollView background to overlay style
        scrollView.opaque = false
        scrollView.backgroundColor = UIColor(white: 0.3, alpha: 0.5)
        
        //hide the image. Fixme: should remove the image from storyboard
        self.meterImage.hidden = true
        //self.meterImage.image = drawMeterImage()
        
        meterView.opaque = false //meter view is transparent
        
        //meterView.frame = CGRectMake(0, 0, meterView.frame.width, 300.0)
        //meterView.bounds = meterView.frame
        //println("meterView: Frame \(meterView.bounds)")
        
        // To refresh the view, to call drawRect
        meterView.setNeedsDisplay()
        
        scrollViewInitialX = scrollViewInitialX ?? self.scrollView.center.x
        self.scrollView.center.x = scrollViewInitialX! + 35.0
        UIView.animateWithDuration(0.25, delay: 0.0, usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.0, options: nil, animations: {
            self.scrollView.alpha = scrollViewAlpha
            self.scrollView.center.x = self.scrollViewInitialX!
        }, completion: nil)
    }
    
    func destroyMeterView() {
        closeMeterView({})
    }
    
    func closeMeterView(completion: () -> Void) {
        self.meterCenter.hidden = true
        scrollViewInitialX = scrollViewInitialX ?? self.scrollView.center.x
        println("current X is \(self.scrollView.center.x)")
        self.scrollView.center.x = scrollViewInitialX!
        println("Initial X is \(scrollViewInitialX)")
        self.updateASM()
        UIView.animateWithDuration(0.25, delay: 0.0, usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.0, options: nil, animations: {
                self.scrollView.alpha = 0.0
                self.scrollView.center.x = self.scrollViewInitialX! + 35.0
            }) { (isComplete: Bool) -> Void in
                self.scrollView.hidden = true
                self.wbIconButton.setImage(UIImage(named: "wb_sunny copy"), forState: UIControlState.Normal)
                completion()
        }
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
            case "WB":
                changeTemperature(value)
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
                let expoVal = self.exposureValue / self.EVMaxAdjusted * 6.0 - 3.0
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
        println("prepareForSegue")
        if segue.identifier == "cameraRollSegue" {
            let vcNav = segue.destinationViewController as? UINavigationController
            if vcNav != nil {
                let vc = vcNav!.viewControllers[0] as? CameraRollViewController
                if vc != nil {
                    vc!.lastImage = self.lastImage
                }
            }
            
        }
        histogramView.hidden = true
        viewDidAppeared = false
    }
}

