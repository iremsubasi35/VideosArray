//
//  VideoProcessingViewModel.swift
//  VideoArray
//
//  Created by İrem Subaşı on 16.03.2024.
//

import AVFoundation
import Vision
import Combine


final class VideoProcessingViewModel: ObservableObject {
    @Published var processedImages: [Data] = []
    
    func processVideo(url: URL) {
        // Videoyu çerçevelere ayırma işlemi
        let processor = VideoProcessor(videoURL: url)
        processor.processVideo { processedImages in
            print(processedImages)
        }
        
        
    }
}
