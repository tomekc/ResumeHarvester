//
//  CameraImageProcessor.swift
//  Harvester
//
//  Created by Tomek on 20.01.2016.
//  Copyright © 2016 SmartRecruiters. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation


class CameraImageProcessor {

    let detector: CIDetector = CameraImageProcessor.buildRectangleDetector()

    func sampleBufferToImage(sampleBuffer: CMSampleBuffer) -> CIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        // Force the type change - pass through opaque buffer
        let opaqueBuffer = Unmanaged<CVImageBuffer>.passUnretained(imageBuffer).toOpaque()
        let pixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(opaqueBuffer).takeUnretainedValue()
        let sourceImage = CIImage(CVPixelBuffer: pixelBuffer, options: nil)
        return sourceImage
    }


    func overlayFeature(rectFeature: CIRectangleFeature?, image: CIImage) -> CIImage {
        if let feature = rectFeature {
            return drawHighlightOverlayForPoints(image,
                    topLeft: feature.topLeft,
                    topRight: feature.topRight,
                    bottomLeft: feature.bottomLeft,
                    bottomRight: feature.bottomRight)
        } else {
            return image
        }

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

    func correctPerspectiveFeature(feature: CIRectangleFeature, image: CIImage) -> CIImage {
        let params: [String:AnyObject] = [
                "inputTopLeft": CIVector(CGPoint: feature.topLeft),
                "inputTopRight": CIVector(CGPoint: feature.topRight),
                "inputBottomLeft": CIVector(CGPoint: feature.bottomLeft),
                "inputBottomRight": CIVector(CGPoint: feature.bottomRight),
        ]
        return image.imageByApplyingFilter("CIPerspectiveCorrection", withInputParameters: params)
    }

    func rotateImage(image: CIImage) -> CIImage {
        if let transform = CIFilter(name: "CIAffineTransform") {
            transform.setValue(image, forKey: kCIInputImageKey)
            let rotation = NSValue(CGAffineTransform: CGAffineTransformMakeRotation(CGFloat(-90.0 * (M_PI / 180.0))))
            transform.setValue(rotation, forKey: "inputTransform")
            if let rotated = transform.outputImage {
                return rotated
            } else {
                return image
            }
        } else {
            return image
        }
    }

    // -----------------------
    // Create feature detector
    class func buildRectangleDetector() -> CIDetector {
        let options: [String:AnyObject] = [
                CIDetectorAccuracy: CIDetectorAccuracyHigh,
                CIDetectorAspectRatio: 1.41
        ]
        return CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: options)
    }

    func detectRectangularFeature(image: CIImage) -> CIRectangleFeature? {
        let features = detector.featuresInImage(image)
        return largestFeature(features as! [CIRectangleFeature])
    }
    
    // Calculates a comparable value of rectangle value
    // i.e. half of perimeter
    func featureSize(feature:CIRectangleFeature) -> Float {
        let p1 = feature.topLeft
        let p2 = feature.topRight
        let width = hypotf(Float(p1.x - p2.x), Float(p1.y - p2.y))
        
        let p3 = feature.bottomLeft
        let height = hypotf(Float(p1.x - p3.x), Float(p1.y - p3.y))
        
        return width + height
    }
    
    func largestFeature(list:[CIRectangleFeature]) -> CIRectangleFeature? {
        if list.count == 0 {
            return nil
        }
        if list.count == 1 {
            return list[0]
        }
        
        let sorted = list.sort { a,b in
            return featureSize(a) > featureSize(b)
        }
        
        return sorted.first
    }

}