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

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCapture()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func setupCapture() {
        do {
            print("Starting capture session")
        let session = AVCaptureSession()
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let input = try AVCaptureDeviceInput(device: device)
        session.addInput(input)
            
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
