//
//  CameraView.swift
//  Harvester
//
//  Created by Tomek on 20.01.2016.
//  Copyright © 2016 Tomek Cejner. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit
import GLKit

class CameraMagica : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let parentView:UIView
    let stillImageOutput = AVCaptureStillImageOutput()
    let sessionQueue:dispatch_queue_t
    var session:AVCaptureSession?
    let imageProcessor = CameraImageProcessor()
    let glContext:EAGLContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
    var coreImageContext:CIContext?
    var glView:GLKView?
    
    init(view:UIView) {
        self.parentView = view
        sessionQueue = dispatch_queue_create("AVSessionQueue", DISPATCH_QUEUE_SERIAL)
        super.init()
        session = self.setupCaptureSession()
        self.createGLView()
    }
    
    // Start video capture and feature detection
    func start() {
        self.session?.startRunning()
    }
    
    // Stop video capture
    func stop() {
        self.session?.stopRunning()
    }
    
    func takeSnapshot(completion:(CIImage) -> ()) {
        
    }
    
    // ---------------------------------------------

    // Build AVCapture
    func setupCaptureSession() -> AVCaptureSession {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        do {
        let input = try AVCaptureDeviceInput(device: device)
        session.addInput(input)
        } catch {
            print("Unable to initialize capture input")
        }
        
        // Build video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [ kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA)]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        session.addOutput(videoOutput)
        videoOutput.connectionWithMediaType(AVMediaTypeVideo).enabled = true
        
        // Connect to still image output
        session.addOutput(stillImageOutput)
        
        return session
    }
    
    // Create GL view inside parent view
    func createGLView() {
        let view = GLKView(frame: self.parentView.bounds)
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        view.context = self.glContext
        view.contentScaleFactor = 1.0
        view.drawableDepthFormat = GLKViewDrawableDepthFormat.Format24
        self.parentView.insertSubview(view, atIndex: 0)
        self.glView = view
    }
    
    
    // Capture Video Output Delegate
    @objc func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        // Rotate the image to portrait
        connection.videoOrientation = AVCaptureVideoOrientation.Portrait
        
        if let image = imageProcessor.sampleBufferToImage(sampleBuffer) {
            let feature = imageProcessor.detectRectangularFeature(image)
            let outputImage = imageProcessor.overlayFeature(feature, image: image)
            
            guard (self.coreImageContext != nil) else { return }
            if EAGLContext.currentContext() != self.glContext {
                EAGLContext.setCurrentContext(self.glContext)
            }
            
            glView?.bindDrawable()
            self.coreImageContext?.drawImage(outputImage, inRect: self.parentView.bounds, fromRect: image.extent)
            glView?.display()            
            
        }
        
        
        
        
    }
    
    
}