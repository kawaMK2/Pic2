//
//  ViewController.swift
//  Pic2
//
//  Created by 石嶺 眞太郎 on 2017/05/01.
//  Copyright © 2017年 石嶺 眞太郎. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var videoDataOutput:AVCaptureVideoDataOutput!
    var session:AVCaptureSession!
    var isUsingFrontCamera:Bool!
    var videoDataOutputQueue:DispatchQueue!
    var previewLayer:CALayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewLayer = CALayer()
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        // ツールバー生成
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0.0, y: view.bounds.size.height - 44.0, width: view.bounds.size.width, height: 44.0))
        let flexibleSpace:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let takePhotoButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.camera, target: self, action: #selector(ViewController.takePhoto(_:)))
        toolbar.items = [flexibleSpace, takePhotoButton, flexibleSpace]
        view.addSubview(toolbar)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupAVCapture()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        teardownAVCapture()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func takePhoto(_ sender: Any) {
        AudioServicesPlaySystemSound(1108);
        DispatchQueue.main.async(execute: {
            UIGraphicsBeginImageContext(self.previewLayer.bounds.size)
            self.previewLayer.render(in: UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            UIImageWriteToSavedPhotosAlbum(image!, self, nil, nil)
        })
    }
    
    func setupAVCapture() {
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetInputPriority
        
        var device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        let deviceInput = AVCaptureDeviceInput()
        
        // キャプチャーセッションに追加
        if (session.canAddInput(deviceInput)) {
            session.addInput(deviceInput)
        }
        
        // 画像出力を作成
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: kCVPixelFormatType_32BGRA]
        
        videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        if (session.canAddOutput(videoDataOutput)) {
            session.addOutput(videoDataOutput)
        }
        
        let videoConnection = videoDataOutput.connection(withMediaType: AVMediaTypeVideo)
        videoConnection?.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue)!
        session.startRunning()
        
    }
    
    func teardownAVCapture() {
        videoDataOutput = nil
    }
    
    func process(image:UIImage) {
        let processedImage = MonochromeFilter.do(image)
        previewLayer.contents = processedImage?.cgImage
    }

    func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        let image = imageFromSampleBuffer(sampleBuffer: sampleBuffer)
        DispatchQueue.main.async{
            self.process(image: image)
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer :CMSampleBuffer) -> UIImage {
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)!
        
        let bytesPerRow: UInt = UInt(CVPixelBufferGetBytesPerRow(imageBuffer))
        let width: UInt = UInt(CVPixelBufferGetWidth(imageBuffer))
        let height: UInt = UInt(CVPixelBufferGetHeight(imageBuffer))
        
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bitsPerCompornent: UInt = 8
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) as UInt32)
        let newContext: CGContext = CGContext(data: baseAddress, width: Int(width), height: Int(height), bitsPerComponent: Int(bitsPerCompornent), bytesPerRow: Int(bytesPerRow), space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        
        let imageRef: CGImage = newContext.makeImage()!
        let resultimage = UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImageOrientation.right)
        
        return resultimage
    }
    
}

