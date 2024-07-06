//
//  VideoProcessor.swift
//  VideoArray
//
//  Created by İrem Subaşı on 16.03.2024.
//

import AVFoundation
import SwiftUI

class VideoProcessor {
    let videoURL: URL
    
    init(videoURL: URL) {
        self.videoURL = videoURL
    }
    
    func processVideo(completion: @escaping ([CGImage]?) -> Void) {
         let asset = AVAsset(url: videoURL)
            
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        let frameRate = 30
        let numberOfFrames = Int(durationSeconds) * frameRate
        
        var imageArray = [CGImage]()
        
        let dispatchGroup = DispatchGroup()
        
        for i in 0..<numberOfFrames {
            let time = CMTimeMake(value: Int64(i), timescale: Int32(frameRate))
            dispatchGroup.enter()
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, error in
                defer {
                    dispatchGroup.leave()
                }
                if let cgImage = cgImage {
                    imageArray.append(cgImage)
                } else {
                    print("Error generating image at time \(time): \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(imageArray)
//            for index in 0 ..< imageArray.count{
//                let uıImage = UIImage(cgImage: imageArray[index])
//                if index ==  5 || index == 75 || index == 149 {
//                    print(uıImage)
//                } //5,75,150
//            }
        }
    }
    
    func createVideo(from images: [CGImage], completion: @escaping (URL?) -> Void) {
        guard !images.isEmpty else {
            completion(nil)
            return
        }
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("output.mp4")
        
        guard let videoWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            completion(nil)
            return
        }
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: images[0].width,
            AVVideoHeightKey: images[0].height
        ]
        
        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: images[0].width,
            kCVPixelBufferHeightKey as String: images[0].height
        ]
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput,
                                                                      sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        videoWriter.add(videoWriterInput)
        
        if videoWriter.startWriting() {
            videoWriter.startSession(atSourceTime: .zero)
            
            var frameCount = 0
            let frameDuration = CMTimeMake(value: 1, timescale: 30) // Assuming 30 fps
            
            videoWriterInput.requestMediaDataWhenReady(on: DispatchQueue.global(qos: .background)) {
                while videoWriterInput.isReadyForMoreMediaData && frameCount < images.count {
                    let currentImage = images[frameCount]
                    if let pixelBuffer = self.pixelBuffer(for: currentImage) {
                        pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: CMTimeMultiply(frameDuration, multiplier: Int32(frameCount)))
                        frameCount += 1
                    } else {
                        print("Error converting CGImage to pixel buffer")
                        completion(nil)
                        return
                    }
                }
                
                videoWriterInput.markAsFinished()
                videoWriter.finishWriting {
                    completion(outputURL)
                }
            }
        }
    }
    
    private func pixelBuffer(for image: CGImage) -> CVPixelBuffer? {
        let width = image.width
        let height = image.height
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, nil, &pixelBuffer)
        
        guard let buffer = pixelBuffer, status == kCVReturnSuccess else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let data = CVPixelBufferGetBaseAddress(buffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else { return nil }
        
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}
