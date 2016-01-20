//
//  CaptureViewController.swift
//  Harvester
//
//  Created by Tomek on 13.01.2016.
//  Copyright © 2016 SmartRecruiters. All rights reserved.
//

import UIKit
import AVFoundation
import GLKit

class CaptureViewController: UIViewController {

    var detector:CIDetector!
    var videoSampler:VideoSamplerDelegate!
    var sessionQueue: dispatch_queue_t!
    var renderContext: CIContext!
    var session:AVCaptureSession!
    var stillImageOutput:AVCaptureStillImageOutput!
    
    var croppedImage:UIImage!
    
    // controls
    @IBOutlet var previewImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessionQueue = dispatch_queue_create("AVSessionQueue", DISPATCH_QUEUE_SERIAL)
        self.detector = buildDetector()
        self.videoSampler = VideoSamplerDelegate(withDetector: self.detector)
        self.videoSampler.delegate = self.gotFeatures

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Setting up here, because in case of failure UIAlertController is presented
        // which requires fully initialized view
        setupCapture()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        session.stopRunning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Create feature detector
    func buildDetector() -> CIDetector {
        let options:[String:AnyObject] = [
            CIDetectorAccuracy: CIDetectorAccuracyHigh,
            CIDetectorAspectRatio: 1.41
        ]
        return CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: options)
    }

    func setupCapture() {
        do {
            print("Starting capture session")
            // Create capture session
            session = AVCaptureSession()
            // Photo preset gives best resolution
            session.sessionPreset = AVCaptureSessionPresetPhoto
            
            let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)

            let input = try AVCaptureDeviceInput(device: device)
            session.addInput(input)
            
            // Build video output
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.videoSettings = [ kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA)]
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self.videoSampler, queue: sessionQueue)
            session.addOutput(videoOutput)
            
            videoOutput.connectionWithMediaType(AVMediaTypeVideo).enabled = true
            
            self.stillImageOutput = AVCaptureStillImageOutput()
            session.addOutput(stillImageOutput)
            
//            let layer = AVCaptureVideoPreviewLayer(session: session)
//            layer.videoGravity = AVLayerVideoGravityResizeAspectFill
//            layer.bounds = self.previewImageView.bounds
//            layer.position = CGPoint(x: CGRectGetMidX(self.previewImageView.bounds), y: CGRectGetMidY(self.previewImageView.bounds))
//            self.previewImageView.layer.addSublayer(layer)
            
            session.startRunning()
            
        } catch {
            print("Camera error")
            let alert = UIAlertController(title: "Camera error", message: "Unable to access camera. Is it present?", preferredStyle: .Alert)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    func gotFeatures(image:CIImage) {
        dispatch_async(dispatch_get_main_queue(),{
            let ctx = CIContext(options: nil)
            let cgimage = ctx.createCGImage(image, fromRect: image.extent)
            self.previewImageView.image = UIImage(CGImage: cgimage)
        })
    }
    
    
    func getImageOutputConnection(imageOutput:AVCaptureStillImageOutput) -> AVCaptureConnection? {
        for conn in (imageOutput.connections as? [AVCaptureConnection])! {
            for port in (conn.inputPorts as? [AVCaptureInputPort])! {
                if port.mediaType == AVMediaTypeVideo {
                    return conn
                }
            }
        }
        return nil
    }
    
    func takeSnapshot(completionHandler:(CIImage) -> ()) {
        guard let connection = getImageOutputConnection(self.stillImageOutput) else { return }
        
        dispatch_suspend(self.sessionQueue)
        
        self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(connection) { (sampleBuffer:CMSampleBuffer!, error:NSError!) -> Void in
            // got image
            if (error != nil) {
                dispatch_resume(self.sessionQueue)
                return
            }
            
            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
            if let ciimage = CIImage(data: imageData, options: nil) {
                print("Captured image: \(ciimage.extent.width)x\(ciimage.extent.width)")
                dispatch_resume(self.sessionQueue)
                completionHandler(ciimage)
            }
            
            
        }
        
    }
    
    
    @IBAction func doSnap(sender: AnyObject) {
        print("SNAP!")
        self.takeSnapshot { image in
            let features = self.detector.featuresInImage(image)
            if let firstShape = features.first, rect = firstShape as? CIRectangleFeature {
                // rec
                let transformedImage = self.videoSampler.correctPerspective(image, feature: rect)
                self.croppedImage = UIImage(CIImage: transformedImage)
                self.performSegueWithIdentifier(R.segue.captureViewController.showSnapshot, sender: nil)
            }
        }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let preview = R.segue.captureViewController.showSnapshot(segue: segue) {
            preview.destinationViewController.image = self.croppedImage
        }
    }

}
