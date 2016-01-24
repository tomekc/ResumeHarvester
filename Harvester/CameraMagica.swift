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

class CameraMagica: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    let parentView: UIView
    let stillImageOutput = AVCaptureStillImageOutput()
    let sessionQueue: dispatch_queue_t
    var session: AVCaptureSession?
    let imageProcessor = CameraImageProcessor()
    let glContext: EAGLContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
    var coreImageContext: CIContext?
    var glView: GLKView?

    let rotationTransform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))

    init(view: UIView) {
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

    func takeSnapshot(completion: (CIImage) -> ()) {
        guard let connection = getImageOutputConnection(self.stillImageOutput) else {
            return
        }

        dispatch_suspend(self.sessionQueue)
        self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(connection) {
            (sampleBuffer: CMSampleBuffer!, error: NSError!) -> Void in
            // got image
            if (error != nil) {
                print("Frame capture error \(error)")
                dispatch_resume(self.sessionQueue)
                return
            }

            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
            if let ciimage = CIImage(data: imageData, options: [kCIImageColorSpace: NSNull()]) {
                print("Captured image: \(ciimage.extent.width)x\(ciimage.extent.width)")
                dispatch_resume(self.sessionQueue)
                completion(ciimage)
            }
        }
    }


    func takeSnapshotOfRectangularFeature(completion: (CIImage) -> ()) {
        self.takeSnapshot {
            image in
            if let rectangle = self.imageProcessor.detectRectangularFeature(image) {
                print("Feature: \(rectangle.topLeft); \(rectangle.topRight); \(rectangle.bottomLeft); \(rectangle.bottomRight)")
                let rectangleImage = self.imageProcessor.correctPerspectiveFeature(rectangle, image: image)
                print("Image after correction \(rectangleImage.extent)")
                let matrix = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
                completion(self.imageProcessor.rotateImage(rectangleImage))
            }

        }
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
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA)]
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

        self.coreImageContext = CIContext(EAGLContext: self.glContext, options: [
                kCIContextWorkingColorSpace: NSNull(),
                kCIContextUseSoftwareRenderer: false
        ])
    }


    // Capture Video Output Delegate
    @objc func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        // Rotate the image to portrait
        if let image = imageProcessor.sampleBufferToImage(sampleBuffer) {
            let feature = imageProcessor.detectRectangularFeature(image)
            let outputImage = imageProcessor.overlayFeature(feature, image: image)

            guard (self.coreImageContext != nil) else {
                return
            }
            if EAGLContext.currentContext() != self.glContext {
                EAGLContext.setCurrentContext(self.glContext)
            }

            glView?.bindDrawable()
            let rotated = imageProcessor.rotateImage(outputImage)
            self.coreImageContext?.drawImage(rotated, inRect: self.parentView.bounds, fromRect: rotated.extent)
            glView?.display()

        }
    }

    func getImageOutputConnection(imageOutput: AVCaptureStillImageOutput) -> AVCaptureConnection? {
        for conn in (imageOutput.connections as? [AVCaptureConnection])! {
            for port in (conn.inputPorts as? [AVCaptureInputPort])! {
                if port.mediaType == AVMediaTypeVideo {
                    return conn
                }
            }
        }
        return nil
    }

}