//
//  AVCoreViewController.swift
//  ProCamera
//
//  Created by Hao Wang on 3/10/15.
//  Copyright (c) 2015 Hao Wang. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import CoreImage
import CoreGraphics
import Accelerate
import MediaPlayer

enum whiteBalanceMode {
    case Auto
    case Sunny
    case Cloudy
    case Temperature(Int)
    init() {
        self = Auto
    }
    func getValue() -> Int {
        switch self {
        case Temperature(let value):
            return value
        default:
            return -1
        }
    }
}

enum ISOMode {
    case Auto, Custom
}


extension Float {
    func format(f: String) -> String {
        return NSString(format: "%\(f)f", self)
    }
}


let histogramBuckets: Int = 16
let histogramCalcIntervalFrames = 10 //every X frames, calc one histogram

class AVCoreViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var initialized = false
    private let whiteBalanceModes = ["Auto", "Sunny", "Cloudy", "Manual"]
    private var capturedImage: UIImageView!
    private var videoDevice: AVCaptureDevice!
    private var captureSession: AVCaptureSession!
    private var stillImageOutput: AVCaptureStillImageOutput!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var flashOn = false
    var lastImage: UIImage?
    var frameImage: CGImage!
    var isoMode: ISOMode = ISOMode.Auto
    var exposureValue: Float = 0.5 // EV
    var currentISOValue: Float?
    var currentExposureDuration: Float64?
    var currentColorTemperature: AVCaptureWhiteBalanceTemperatureAndTintValues!
    var histogramFilter: CIFilter?
    var _captureSessionQueue: dispatch_queue_t?
    var currentOutput: AVCaptureOutput!
    var useStillImageOutput = true
    var histogramDataImage: CIImage!
    var histogramDisplayImage: UIImage!
    var shootMode: Int! //0 = Auto, 1 = Tv, 2= Manual
    var lastHistogramEV: Double?
    var enableLastHistogramEV = false
    var EVMax: Float = 15.0
    var EVMaxAdjusted: Float = 15.0
    var gettingFrame: Bool = false
    var timer: dispatch_source_t!
    var histogramRaw: [Int] = Array(count: histogramBuckets, repeatedValue: 0)
    var configLocked: Bool = false
    var currentHistogramFrameCount: Int = 0
    
    
    // Some default settings
    let EXPOSURE_DURATION_POWER:Float = 4.0 //the exposure slider gain
    let EXPOSURE_MINIMUM_DURATION:Float64 = 1.0/2000.0
    
    func initialize() {
        if !initialized {
            histogramRaw.reserveCapacity(histogramBuckets)
            isoMode = .Auto
            _captureSessionQueue = dispatch_queue_create("capture_session_queue", nil);
            dispatch_async(_captureSessionQueue, { () -> Void in
                self.captureSession = AVCaptureSession()
                self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto
                self.videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) //default is back camera
                var error: NSError?
                var input = AVCaptureDeviceInput(device: self.videoDevice, error: &error)
                if error == nil && self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                    // @Discussion:
                    // Need AVCaptureVideoDataOutput for histogram
                    // AND
                    // AVCaptureStillImageOutput for photo capture
                    // CoreImage wants BGRA pixel format
                    let outputSettings: NSDictionary = [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(integer: kCVPixelFormatType_32BGRA)]
                    self.videoDataOutput = AVCaptureVideoDataOutput()
                    self.videoDataOutput.videoSettings = outputSettings
                    self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
                    self.videoDataOutput.setSampleBufferDelegate(self, queue: self._captureSessionQueue)
                    
                    if self.captureSession.canAddOutput(self.videoDataOutput) {
                        self.captureSession.addOutput(self.videoDataOutput) //add output
                    }
                
                    self.stillImageOutput = AVCaptureStillImageOutput()
                    self.stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                    self.stillImageOutput.highResolutionStillImageOutputEnabled = true
                    self.currentOutput = self.stillImageOutput
                    
                    if self.captureSession.canAddOutput(self.stillImageOutput) {
                        self.captureSession.addOutput(self.stillImageOutput)
                        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect
                        self.previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.LandscapeLeft
                        self.captureSession.startRunning()
                        self.initialized = true
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.postInitilize()
                        })
                    }
                    return ()
                    //TODO: send notification
                }
            })
        }
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        var formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer)
        var mediaType = CMFormatDescriptionGetMediaType(formatDesc)
        if (Int(mediaType) != kCMMediaType_Audio) {
            //video
            //calc histogram every X frames
            if ++currentHistogramFrameCount >= histogramCalcIntervalFrames {
                //calc histogram
                
                let imageBuffer: CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)
                var sourceImage = CIImage(CVPixelBuffer: imageBuffer, options: nil)
                if sourceImage != nil {
                    self.calcHistogram(sourceImage)
                }
                currentHistogramFrameCount = 0
            }
        }
    }
    
    func runFilter(cameraImage: CIImage, filters: NSArray) -> CIImage? {
        var currentImage: CIImage?
        var activeInputs: [CIImage] = []
        
        for filter_i in filters {
            if let filter = filter_i as? CIFilter {
                filter.setValue(cameraImage, forKey: kCIInputImageKey)
                currentImage = filter.outputImage;
                if currentImage == nil {
                    return nil
                } else {
                    activeInputs.append(currentImage!)
                }
            }
        }
        
        if CGRectIsEmpty(currentImage!.extent()) {
            return nil
        }
        return currentImage;
    }
    
    func postInitilize() {
        listenVolumeButton()
    }
    
    func lockConfig(complete: () -> ()) {
        if initialized {
            configLocked = true
            var error: NSError?
            videoDevice.lockForConfiguration(&error)
            if error == nil {
                complete()
                videoDevice.unlockForConfiguration()
                self.postChangeCameraSetting()
                configLocked = false
            } else {
                println("lockForConfiguration Failed \(error)")
            }
        }
    }
    
    func setWhiteBalanceMode(mode: whiteBalanceMode) {
        var wbMode: AVCaptureWhiteBalanceMode
        switch (mode) {
        case .Auto:
            wbMode = .ContinuousAutoWhiteBalance
        default:
            wbMode = .Locked
        }
        var temperatureValue = mode.getValue()
        if (temperatureValue > -1) {
            //means not auto
            changeTemperature(Float(temperatureValue))
        }
        lockConfig { () -> () in
            if self.videoDevice.isWhiteBalanceModeSupported(wbMode) {
                self.videoDevice.whiteBalanceMode = wbMode;
            } else {
                println("White balance mode is not supported");
            }
        }
    }
    
    func changeTemperature(value: Float) {
        
        var mappedValue = value * 5000.0 + 3000.0 //map 0.0 - 1.0 to 3000 - 8000
        println("wb=\(value)")
        self.currentColorTemperature = AVCaptureWhiteBalanceTemperatureAndTintValues(temperature: mappedValue, tint: 0.0)
        if initialized {
            setWhiteBalanceGains(videoDevice.deviceWhiteBalanceGainsForTemperatureAndTintValues(self.currentColorTemperature))
        }
    }
    
    // Normalize the gain so it does not exceed
    func normalizedGains(gains:AVCaptureWhiteBalanceGains) -> AVCaptureWhiteBalanceGains {
        var g = gains;
        g.redGain = max(1.0, g.redGain);
        g.greenGain = max(1.0, g.greenGain);
        g.blueGain = max(1.0, g.blueGain);
        
        g.redGain = min(videoDevice.maxWhiteBalanceGain, g.redGain);
        g.greenGain = min(videoDevice.maxWhiteBalanceGain, g.greenGain);
        g.blueGain = min(videoDevice.maxWhiteBalanceGain, g.blueGain);
        
        return g;
    }
    
    //Set the white balance gain
    func setWhiteBalanceGains(gains: AVCaptureWhiteBalanceGains) {
        lockConfig { () -> () in
            self.videoDevice.setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains(self.normalizedGains(gains), completionHandler: nil)
        }
    }
    
    // Available modes:
    // .Locked .AutoExpose .ContinuousAutoExposure .Custom
    func changeExposureMode(mode: AVCaptureExposureMode) {
        lockConfig { () -> () in
            if self.videoDevice.isExposureModeSupported(mode) {
                self.videoDevice.exposureMode = mode
            }
        }
    }
    
    func changeExposureDuration(value: Float) {
        if initialized {
            let p = Float64(pow(value, EXPOSURE_DURATION_POWER)) // Apply power function to expand slider's low-end range
            let minDurationSeconds = Float64(max(CMTimeGetSeconds(videoDevice.activeFormat.minExposureDuration), EXPOSURE_MINIMUM_DURATION))
            let maxDurationSeconds = Float64(CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration))
            let newDurationSeconds = Float64(p * (maxDurationSeconds - minDurationSeconds)) + minDurationSeconds // Scale from 0-1 slider range to actual duration
            
            if (videoDevice.exposureMode == .Custom) {
                lockConfig { () -> () in
                    
                    if self.isoMode == .Auto {
                        // Going to calculate the correct exposure EV
                        // Keep EV stay the same
                        // Need to calculate the ISO based on current image exposure
                        // exposureTime * ISO = EV
                        // ISO from 29 to 464
                        // exposureTime from 1/8000 to 1/2
                        // Let's assume EV = 14.45
                        
                        //self.exposureValue = 14.45
                        self.currentISOValue = self.capISO(Float(self.exposureValue) / Float(newDurationSeconds))
                        //println("iso=\(self.currentISOValue) expo=\(newDurationSeconds)")
                    } else if self.currentISOValue == nil{
                        self.currentISOValue = AVCaptureISOCurrent
                    }
                    self.currentExposureDuration = newDurationSeconds
                    let newExposureTime = CMTimeMakeWithSeconds(Float64(newDurationSeconds), 1000*1000*1000)
                    self.videoDevice.setExposureModeCustomWithDuration(newExposureTime, ISO: self.currentISOValue!, completionHandler: nil)
                }
            }
        } else {
            println("not initilized. changeExposureDuration Fail")
        }
    }
    
    //Only adjust max EV but does not chang EV value
    func adjustMaxEV() {
        // EV Mapping
        // 1/129 s = 0 - 15
        // 1/79 s = 0 - 25
        // 1/1999 = 0 - 0.902639
        //EV_max should be related to current exposure Duration
        let k: Float64 = (0.902639 - 25.0) / (1.0 / 1999.0 - 1.0 / 79.0)
        let b: Float64 = 25.0 - k / 79.0
        EVMaxAdjusted = Float(k * Float64(currentExposureDuration!) + b)
        println("currentExposureDuration \(currentExposureDuration) EVAdjusted=\(EVMaxAdjusted), EV= \(exposureValue)")
    }
    
    func changeEV(value: Float) {
        adjustMaxEV()
        exposureValue = value * EVMaxAdjusted
        
        
        //This is to try autoadjustEV based on histogram exposure. but doesn't seem to work well due to infinite feedback loop
        if lastHistogramEV != nil && self.enableLastHistogramEV {
            let evPercent = exposureValue / EVMax
            if lastHistogramEV! < 5000.0 && evPercent > 0.3 { //When EV is not too low but exposure is too low
                // Under Exposure. Make EV_max Larger
                exposureValue += Float(lastHistogramEV!) / 2500.0 // + from 0 to 10
            } else if lastHistogramEV! > 40000.0 && evPercent < 0.7 { //EV is not too high, but exposure is too high
                exposureValue *= 40000.0 / Float(lastHistogramEV!) //scale down
            }
        }
        
        if initialized && shootMode == 1 && self.isoMode == .Auto {
            //Need to auto adjust ISO
            self.currentISOValue = self.capISO(Float(exposureValue) / Float(currentExposureDuration!))
            lockConfig { () -> () in
                self.videoDevice.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, ISO: self.currentISOValue!, completionHandler: nil)
            }
        }
    }
    
    func getCurrentValueNormalized(name: String) -> Float! {
        var ret: Float = 0.5
        if name == "EV" {
            adjustMaxEV()
            ret = exposureValue / EVMaxAdjusted
        } else if name == "ISO" {
            if currentISOValue != nil {
                ret = (currentISOValue! - self.videoDevice.activeFormat.minISO) /  (self.videoDevice.activeFormat.maxISO - self.videoDevice.activeFormat.minISO)
            }
        } else if name == "SS"{ //shuttle speed
            let minDurationSeconds = Float64(max(CMTimeGetSeconds(videoDevice.activeFormat.minExposureDuration), EXPOSURE_MINIMUM_DURATION))
            let maxDurationSeconds = Float64(CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration))
            if currentExposureDuration != nil {
                let val = Float((currentExposureDuration! - minDurationSeconds) / (maxDurationSeconds - minDurationSeconds))
                ret = Float(sqrt(sqrt(val))) // Apply reverse power
            }
        } else if name == "WB" { //White balance
            if self.currentColorTemperature != nil {
                ret = (currentColorTemperature.temperature - 3000.0) / 500.0
            }
        }
        ret = min(ret, 1.0)
        ret = max(ret, 0.0)
        return ret
    }
    
    func capISO(value: Float) -> Float {
        if value > self.videoDevice.activeFormat.maxISO{
            return self.videoDevice.activeFormat.maxISO
        } else if value < self.videoDevice.activeFormat.minISO{
            return self.videoDevice.activeFormat.minISO
        }
        return value
    }
    
    func calcISOFromNormalizedValue(value: Float) -> Float {
        if initialized {
            var _value = value
            if _value > 1.0 {
                _value = 1.0
            }
            //map it to the proper iso value
            let minimumValue = self.videoDevice.activeFormat.minISO
            let maximumValue = self.videoDevice.activeFormat.maxISO
            let newValue = _value * (maximumValue - minimumValue) + minimumValue
            return newValue
        }
        return Float(0.0)
    }
    
    //input value from 0.0 to 1.0
    func changeISO(value: Float) {
        let newValue = calcISOFromNormalizedValue(value)
        lockConfig { () -> () in
            self.currentISOValue = newValue
            self.videoDevice.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, ISO: newValue, completionHandler: nil)
        }
    }
    
    func setFlashMode(on: Bool) {
        self.flashOn = on
    }
    
    func playShutterSound() {
        let path = NSBundle.mainBundle().pathForResource("shutter_sound", ofType: "mp3")
        var theAudio = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: path!), error: nil)
        theAudio.prepareToPlay()
        theAudio.volume = 1.0
        theAudio.play()
    }
    
    //save photo to camera roll
    func takePhoto() {
        if initialized {
            if let videoConnection = currentOutput!.connectionWithMediaType(AVMediaTypeVideo) {
                videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
                if useStillImageOutput {
                    stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                        if (sampleBuffer != nil) {
                            var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                            var dataProvider = CGDataProviderCreateWithCFData(imageData)
                            var cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, kCGRenderingIntentDefault)
                            self.lastImage = UIImage(CGImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.Right)
                            //save to camera roll
                            self.beforeSavePhoto()
                            UIImageWriteToSavedPhotosAlbum(self.lastImage, nil, nil, nil)
                            self.postSavePhoto()
                            //self.playShutterSound()
                            println("Take Photo")
                        }
                    })
                } else {
                    //using videoDataOutput
                }
            }
        } else {
            println("take photo failed. not initialized")
        }
    }
    
    func getFrame(complete: () -> ()) {
        if initialized && !self.gettingFrame {
            dispatch_async(self._captureSessionQueue, { () -> Void in
                self.gettingFrame = true
                if let videoConnection = self.currentOutput!.connectionWithMediaType(AVMediaTypeVideo) {
                    videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
                    if self.useStillImageOutput {
                        self.stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                            if (sampleBuffer != nil) {
                                var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                                var dataProvider = CGDataProviderCreateWithCFData(imageData)
                                self.frameImage = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, kCGRenderingIntentDefault)
                                complete()
                                self.gettingFrame = false
                            }
                        })
                    } else {
                        //using videoDataOutput
                    }
                    self.gettingFrame = false
                }
                self.gettingFrame = false
            })
        }
    }
    
    //Deprecated.
    func startTimer() {
        let queue = dispatch_queue_create("com.procam.timer", nil)
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 1 * NSEC_PER_SEC) // every 5 seconds, with leeway of 1 second
        dispatch_source_set_event_handler(timer) {
            if !self.configLocked {
                //self.calcHistogram()
            }
        }
        dispatch_resume(timer)
    }
    
    func stopTimer() {
        dispatch_source_cancel(timer)
        timer = nil
    }
    
    // scaleDiv = divide by Int
    func scaleDownCGImage(image: CGImage, scale: Float) -> CGImage!{
        var scaleDiv = UInt(1.0 / scale)
        let width = CGImageGetWidth(image) / scaleDiv
        let height = CGImageGetHeight(image) / scaleDiv
        let bitsPerComponent = CGImageGetBitsPerComponent(image)
        let bytesPerRow = CGImageGetBytesPerRow(image)
        let colorSpace = CGImageGetColorSpace(image)
        let bitmapInfo = CGImageGetBitmapInfo(image)
        let context = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)
        CGContextSetInterpolationQuality(context, kCGInterpolationMedium)
        let imgSize = CGSize(width: Int(width), height: Int(height))
        CGContextDrawImage(context, CGRect(origin: CGPointZero, size: imgSize), image)
        //println("scaled image for histogram calc \(imgSize)")
        return CGBitmapContextCreateImage(context)
    }
    
    func calcHistogram(ciImage: CIImage!) {
        if initialized {
            dispatch_async(self._captureSessionQueue, { () -> Void in
                if ciImage != nil {
                    /* //Was trying to use a filter but doesn't work out
                    let params: NSDictionary = [
                        String(kCIInputImageKey): ciImage,
                        String(kCIInputExtentKey): CIVector(CGRect: ciImage.extent()),
                        "inputCount": 256
                    ]
                    self.histogramFilter = CIFilter(name: "CIAreaHistogram", withInputParameters: params)

                    self.histogramDataImage = self.histogramFilter!.outputImage
                    */
                    
                    self.getHistogramRaw(ciImage)
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        self.postCalcHistogram()
                    })
                }
            })
        }
    }
    
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage! {
        let context = CIContext(options: nil)
        if context != nil {
            return context.createCGImage(inputImage, fromRect: inputImage.extent())
        }
        return nil
    }
    
    func getHistogramRaw(dataImage: CIImage) {
        var cgImage = convertCIImageToCGImage(dataImage)
        cgImage = scaleDownCGImage(cgImage, scale: 0.5)
        var imageData: CFDataRef = CGDataProviderCopyData(CGImageGetDataProvider(cgImage))
        var dataInput: UnsafePointer<UInt8> = CFDataGetBytePtr(imageData)
        var dataInputMutable = UnsafeMutablePointer<Void>(dataInput)
        var height: vImagePixelCount = CGImageGetHeight(cgImage)
        var width: vImagePixelCount = CGImageGetWidth(cgImage)
        var vImageBuffer = vImage_Buffer(data: dataInputMutable, height: height, width: width, rowBytes: CGImageGetBytesPerRow(cgImage))
        var r = UnsafeMutablePointer<vImagePixelCount>.alloc(256)
        var g = UnsafeMutablePointer<vImagePixelCount>.alloc(256)
        var b = UnsafeMutablePointer<vImagePixelCount>.alloc(256)
        var a = UnsafeMutablePointer<vImagePixelCount>.alloc(256)
        var histogram = UnsafeMutablePointer<UnsafeMutablePointer<vImagePixelCount>>.alloc(4)
        histogram[0] = r
        histogram[1] = g
        histogram[2] = b
        histogram[3] = a
        
        var error:vImage_Error = vImageHistogramCalculation_ARGB8888(&vImageBuffer, histogram, 0);
        
        if (error == kvImageNoError) {
            let pixCountRefNum: Double = 1.0
            var totalExpoVal = 0.0
            //clear histogramRaw
            histogramRaw = Array(count: histogramBuckets, repeatedValue: 0)
            for var j = 0; j < 256; j++ {
                let currentVal = Double(histogram[0][j] + histogram[1][j] + histogram[2][j]) / pixCountRefNum
                if currentVal > 0 {
                    //find out which bucket it is in
                    let bucketNum = j / histogramBuckets
                    histogramRaw[bucketNum] += Int(currentVal)
                    //println("j=\(j),\(currentVal)")
                    if self.enableLastHistogramEV {
                        totalExpoVal += currentVal * Double(j)
                    }
                }
            }
            //println("totalExpoVal=\(totalExpoVal)")
            if self.enableLastHistogramEV {
                lastHistogramEV = totalExpoVal
            }
            //delloc
            r.dealloc(256)
            g.dealloc(256)
            b.dealloc(256)
            a.dealloc(256)
            histogram.dealloc(4)
        } else {
            println("Histogram vImage error: \(error)")
        }
    }
    
    func processHistogram() {
        
    }
    
    func generateHistogramImageFromDataImage(dataImage: CIImage!) -> UIImage! {
        if dataImage != nil {
            let context = CIContext(options: nil)
            let params = [String(kCIInputImageKey): dataImage]
            let filter = CIFilter(name: "CIHistogramDisplayFilter", withInputParameters: params)
            var outputImage = filter.outputImage
            let outExtent = outputImage.extent()
            let cgImage = context.createCGImage(outputImage, fromRect: outExtent)
            let outUIImage = UIImage(CGImage: cgImage)
            return outUIImage
        }
        return nil
    }
    
    func postCalcHistogram() {
        
    }


    
    
    func applyFilter(image: CIImage) {
        var filter = CIFilter(name: "CISepiaTone")
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(0.8, forKey: kCIInputIntensityKey)
        let result = filter.valueForKey(kCIOutputImageKey) as CIImage
        let context: CGRect = result.extent()
    }
    
    func beforeSavePhoto() {
        
    }
    
    func postSavePhoto() {
        
    }
    
    func postChangeCameraSetting() {
        
    }
    
    func FloatToDenominator(value: Float) -> Int {
        if value > 0.0 {
            let denominator = 1.0 / value
            return Int(denominator)
        }
        return 0
    }
    
    func listenVolumeButton(){
        let audioSession = AVAudioSession.sharedInstance()
        audioSession.setActive(true, error: nil)
        audioSession.addObserver(self, forKeyPath: "outputVolume",
            options: NSKeyValueObservingOptions.New, context: nil)
        //hide volumn view
        let rect = CGRect(x: -500.0, y: -500.0, width: 0, height: 0)
        var volumeView: MPVolumeView = MPVolumeView(frame: rect)
        view.addSubview(volumeView)
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject,
        change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
            if keyPath == "outputVolume"{
                takePhoto()
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
