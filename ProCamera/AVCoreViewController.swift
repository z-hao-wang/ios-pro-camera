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
    case Auto
    case Custom
}

class AVCoreViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var initialized = false
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
    var histogramFilter: CIFilter?
    var _captureSessionQueue: dispatch_queue_t?
    var currentOutput: AVCaptureOutput!
    var useStillImageOutput = true
    var histogramDataImage: CIImage!
    var histogramDisplayImage: UIImage!
    
    // Some default settings
    let EXPOSURE_DURATION_POWER:Float = 5.0 //the exposure slider gain
    let EXPOSURE_MINIMUM_DURATION:Float64 = 1.0/1000.0
    
    func initialize() {
        if !initialized {
            _captureSessionQueue = dispatch_queue_create("capture_session_queue", nil);
            dispatch_async(_captureSessionQueue, { () -> Void in
                self.captureSession = AVCaptureSession()
                self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto
                self.videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) //default is back camera
                var error: NSError?
                var input = AVCaptureDeviceInput(device: self.videoDevice, error: &error)
                if error == nil && self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                    if !self.useStillImageOutput {
                        // CoreImage wants BGRA pixel format
                        let outputSettings: NSDictionary = [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(integer: kCVPixelFormatType_32BGRA)]
                        self.videoDataOutput = AVCaptureVideoDataOutput()
                        self.videoDataOutput.videoSettings = outputSettings
                        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
                        self.videoDataOutput.setSampleBufferDelegate(self, queue: self._captureSessionQueue)
                        self.currentOutput = self.videoDataOutput
                    } else {
                        self.stillImageOutput = AVCaptureStillImageOutput()
                        self.stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                        self.stillImageOutput.highResolutionStillImageOutputEnabled = true
                        self.currentOutput = self.stillImageOutput
                    }
                    if self.captureSession.canAddOutput(self.currentOutput) {
                        self.captureSession.addOutput(self.currentOutput)
                        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect
                        self.previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.Portrait
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
            //video writing
            //TODO: Write output videos and audios.
            println("outputsample buffer")
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
        
    }
    
    func lockConfig(complete: () -> ()) {
        if initialized {
            var error: NSError?
            videoDevice.lockForConfiguration(&error)
            if error == nil {
                complete()
                videoDevice.unlockForConfiguration()
                self.postChangeCameraSetting()
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
        var temperatureAndTint = AVCaptureWhiteBalanceTemperatureAndTintValues(temperature: mappedValue, tint: 0.0)
        if initialized {
            setWhiteBalanceGains(videoDevice.deviceWhiteBalanceGainsForTemperatureAndTintValues(temperatureAndTint))
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
                    self.currentISOValue = AVCaptureISOCurrent
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
                        println("iso=\(self.currentISOValue) expo=\(newDurationSeconds)")
                    }
                    self.currentExposureDuration = newDurationSeconds
                    let newExposureTime = CMTimeMakeWithSeconds(Float64(newDurationSeconds), 1000*1000*1000)
                    self.videoDevice.setExposureModeCustomWithDuration(newExposureTime, ISO: self.currentISOValue!, completionHandler: nil)
                }
            }
        } else {
            println("not initilized. changeExposureDuration Fail");
        }
    }
    
    func changeEV(value: Float) {
        exposureValue = value * 10.0
        if initialized && self.isoMode == .Auto {
            //Need to auto adjust ISO
            self.currentISOValue = self.capISO(Float(exposureValue) / Float(currentExposureDuration!))
            lockConfig { () -> () in
                self.videoDevice.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, ISO: self.currentISOValue!, completionHandler: nil)
            }
        }
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
    
    //input value from 0.0 to 1.0
    func changeISO(value: Float) {
        let newValue = calcISOFromNormalizedValue(value)
        lockConfig { () -> () in
            self.videoDevice.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, ISO: newValue, completionHandler: nil)
        }
    }
    
    func setFlashMode(on: Bool) {
        self.flashOn = on
        //temp test
        if initialized {
            getFrame {
                self.calcHistogram()
            }
        }
        
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
        if initialized {
            if let videoConnection = currentOutput!.connectionWithMediaType(AVMediaTypeVideo) {
                videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
                if useStillImageOutput {
                    stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                        if (sampleBuffer != nil) {
                            var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                            var dataProvider = CGDataProviderCreateWithCFData(imageData)
                            self.frameImage = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, kCGRenderingIntentDefault)
                            complete()
                        }
                    })
                } else {
                    //using videoDataOutput
                }
            }
        }
    }
    
    func calcHistogram() {
        dispatch_async(self._captureSessionQueue, { () -> Void in
            
            let ciImage = CIImage(CGImage: self.frameImage)
            let params: NSDictionary = [
                String(kCIInputImageKey): ciImage,
                String(kCIInputExtentKey): CIVector(CGRect: ciImage.extent()),
                "inputCount": 256
            ]
            self.histogramFilter = CIFilter(name: "CIAreaHistogram", withInputParameters: params)
            
            self.histogramDataImage = self.histogramFilter!.outputImage
            self.getHistogramRaw(self.histogramDataImage)
            
            self.histogramDisplayImage = self.generateHistogramImageFromDataImage(self.histogramDataImage)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.postCalcHistogram()
            })
        })
    }
    
    func getHistogramRaw(dataImage: CIImage!) {
        let context = CIContext(options: nil)
        let outExtent = dataImage.extent()
        let cgImage = context.createCGImage(dataImage, fromRect: outExtent)
        let rawData = CGDataProviderCopyData(CGImageGetDataProvider(cgImage))
        let pixelData = CFDataGetBytePtr(rawData)
        let dataLength = CFDataGetLength(rawData);
        let red = 0
        let green = 1
        let blue = 2
        for var index = 0; index < dataLength; index++ {
            //let g = pixelData[index + green]
            let r = pixelData[index + red]
            //let b = pixelData[index + blue]
            if r != 0 {
                println("rgb=\(index):\(r)")
            }
            
        }
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
