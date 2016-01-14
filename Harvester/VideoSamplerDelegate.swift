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

    typealias Handler = (CIImage) -> ()
    
    var detector:CIDetector
    var delegate:Handler?
    
    init(withDetector:CIDetector) {
        self.detector = withDetector
    }

    
    
    // Delegate method called for each captured frame
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        connection.videoOrientation = AVCaptureVideoOrientation.Portrait
        getImageFromSampleBuffer(sampleBuffer)
    }
    
    // Create CIImage from pixel buffer
    func getImageFromSampleBuffer(sampleBuffer:CMSampleBuffer) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        // Force the type change - pass through opaque buffer
        let opaqueBuffer = Unmanaged<CVImageBuffer>.passUnretained(imageBuffer).toOpaque()
        let pixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(opaqueBuffer).takeUnretainedValue()
        let sourceImage = CIImage(CVPixelBuffer: pixelBuffer, options: nil)
        let resultImage = detectRectangle(sourceImage)
        delegate?(resultImage)

    }
    
    func detectRectangle(image:CIImage) -> CIImage {
        let features = detector.featuresInImage(image)
        if let firstShape = features.first, rect = firstShape as? CIRectangleFeature {
            // draw on image
            return drawHighlightOverlayForPoints(image,
                topLeft: rect.topLeft,
                topRight: rect.topRight,
                bottomLeft: rect.bottomLeft,
                bottomRight: rect.bottomRight)
        }
        return image
    }
    
    
    func drawHighlightOverlayForPoints(image: CIImage, topLeft: CGPoint, topRight: CGPoint,
        bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
            var overlay = CIImage(color: CIColor(red: 1.0, green: 0, blue: 0, alpha: 0.5))
            overlay = overlay.imageByCroppingToRect(image.extent)
            overlay = overlay.imageByApplyingFilter("CIPerspectiveTransformWithExtent",
                withInputParameters: [
                    "inputExtent": CIVector(CGRect: image.extent),
                    "inputTopLeft": CIVector(CGPoint: topLeft),
                    "inputTopRight": CIVector(CGPoint: topRight),
                    "inputBottomLeft": CIVector(CGPoint: bottomLeft),
                    "inputBottomRight": CIVector(CGPoint: bottomRight)
                ])
            return overlay.imageByCompositingOverImage(image)
    }
    
}
