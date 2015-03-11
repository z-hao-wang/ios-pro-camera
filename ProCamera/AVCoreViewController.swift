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


class AVCoreViewController: UIViewController {

    private var initialized = false
    private var capturedImage: UIImageView!
    private var videoDevice: AVCaptureDevice!
    private var captureSession: AVCaptureSession!
    private var stillImageOutput: AVCaptureStillImageOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    //some default settings
    let EXPOSURE_DURATION_POWER:Float = 5.0 //the exposure slider gain
    let EXPOSURE_MINIMUM_DURATION:Float64 = 1.0/1000.0
    
    func initialize() {
        if !initialized {
            captureSession = AVCaptureSession()
            captureSession.sessionPreset = AVCaptureSessionPresetPhoto
            videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) //default is back camera
            var error: NSError?
            var input = AVCaptureDeviceInput(device: videoDevice, error: &error)
            if error == nil && captureSession.canAddInput(input) {
                captureSession.addInput(input)
                
                stillImageOutput = AVCaptureStillImageOutput()
                stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                if captureSession.canAddOutput(stillImageOutput) {
                    captureSession.addOutput(stillImageOutput)
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    previewLayer.videoGravity = AVLayerVideoGravityResizeAspect
                    previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.Portrait
                    postInitilize()
                    captureSession.startRunning()
                }
                initialized = true
            }
        }
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
            }
            println("lockForConfiguration Failed \(error)")
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
        let p = Float64(pow(value, EXPOSURE_DURATION_POWER)) // Apply power function to expand slider's low-end range
        let minDurationSeconds = Float64(max(CMTimeGetSeconds(videoDevice.activeFormat.minExposureDuration), EXPOSURE_MINIMUM_DURATION))
        let maxDurationSeconds = Float64(CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration))
        let newDurationSeconds = Float64(p * (maxDurationSeconds - minDurationSeconds))// + minDurationSeconds // Scale from 0-1 slider range to actual duration
        if (videoDevice.exposureMode == .Custom) {
            lockConfig { () -> () in
                self.videoDevice.setExposureModeCustomWithDuration(CMTimeMakeWithSeconds(Float64(newDurationSeconds), 1000*1000*1000), ISO: AVCaptureISOCurrent, completionHandler: nil)
            }
        }
    }
    
    func changeISO(value:Float) {
        lockConfig { () -> () in
            self.videoDevice.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, ISO: value, completionHandler: nil)
        }
    }
    
    //save photo to camera roll
    func takePhoto() {
        if let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo) {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                if (sampleBuffer != nil) {
                    var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    var dataProvider = CGDataProviderCreateWithCFData(imageData)
                    var cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, kCGRenderingIntentDefault)
                    
                    var image = UIImage(CGImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.Right)
                    //save to camera roll
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
            })
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
