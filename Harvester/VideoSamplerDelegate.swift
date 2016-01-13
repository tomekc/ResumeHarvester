//
//  VideoSamplerDelegate.swift
//  Harvester
//
//  Created by Tomek on 13.01.2016.
//  Copyright © 2016 SmartRecruiters. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit

class VideoSamplerDelegate : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var detector:CIDetector
    
    init(withDetector:CIDetector) {
        self.detector = withDetector
    }

    
    // Delegate method called for each captured frame
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        getImageFromSampleBuffer(sampleBuffer)
    }
    
    // Create CIImage from pixel buffer
    func getImageFromSampleBuffer(sampleBuffer:CMSampleBuffer) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        // Force the type change - pass through opaque buffer
        let opaqueBuffer = Unmanaged<CVImageBuffer>.passUnretained(imageBuffer).toOpaque()
        let pixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(opaqueBuffer).takeUnretainedValue()
        
        let sourceImage = CIImage(CVPixelBuffer: pixelBuffer, options: nil)

        detectRectangle(sourceImage)
        
    }
    
    func detectRectangle(image:CIImage) {
        let features = detector.featuresInImage(image)
        for feature in features as! [CIRectangleFeature] {
                print("Feature \(feature.topLeft) - \(feature.bottomRight)")
        }
    }
    
}
