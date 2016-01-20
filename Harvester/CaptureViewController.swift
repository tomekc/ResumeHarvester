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

    var croppedImage:UIImage!
    
    var camera:CameraMagica?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.camera = CameraMagica(view: self.view)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.camera?.start()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func doSnap(sender: AnyObject) {
        print("SNAP!")
        camera?.takeSnapshotOfRectangularFeature { image in
            self.croppedImage = UIImage(CIImage: image)
            self.performSegueWithIdentifier(R.segue.captureViewController.showSnapshot, sender: nil)
            
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
