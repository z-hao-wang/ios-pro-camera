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

    var initialized = false
    var capturedImage: UIImageView!
    var videoDevice: AVCaptureDevice!
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCaptureStillImageOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
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
        var error: NSError?
        videoDevice.lockForConfiguration(&error)
        if error == nil {
            if videoDevice.isWhiteBalanceModeSupported(wbMode) {
                self.videoDevice.whiteBalanceMode = wbMode;
            } else {
                println("White balance mode is not supported");
            }
            videoDevice.unlockForConfiguration()
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
        var error: NSError?
        videoDevice.lockForConfiguration(&error)
        if (error == nil) {
            
            videoDevice.setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains(normalizedGains(gains), completionHandler: nil)
            videoDevice.unlockForConfiguration()
        } else {
            println(error);
        }
    }
    
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
