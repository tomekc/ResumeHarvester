//
//  CaptureViewController.swift
//  Harvester
//
//  Created by Tomek on 13.01.2016.
//  Copyright © 2016 SmartRecruiters. All rights reserved.
//

import UIKit
import AVFoundation

class CaptureViewController: UIViewController {

    var detector:CIDetector!
    var videoSampler:VideoSamplerDelegate!
    var sessionQueue: dispatch_queue_t!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sessionQueue = dispatch_queue_create("AVSessionQueue", DISPATCH_QUEUE_SERIAL)
        self.detector = buildDetector()
        self.videoSampler = VideoSamplerDelegate(withDetector: self.detector)
        setupCapture()

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
            let session = AVCaptureSession()
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
            
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = AVLayerVideoGravityResizeAspectFill
            layer.bounds = self.view.bounds
            layer.position = CGPoint(x: CGRectGetMidX(self.view.bounds), y: CGRectGetMidY(self.view.bounds))
            self.view.layer.addSublayer(layer)
            
            session.startRunning()
            
        } catch {
            let alert = UIAlertController(title: "Camera error", message: "Unable to use camera", preferredStyle: .Alert)
            self.presentViewController(alert, animated: true, completion: nil)
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
