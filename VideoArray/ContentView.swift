//
//  ContentView.swift
//  VideoArray
//
//  Created by İrem Subaşı on 16.03.2024.
//

import SwiftUI
import Vision
import AVFoundation

struct ContentView: View {
    @StateObject private var viewModel = VideoProcessingViewModel()
    @State private var isProcessing = false
    var body: some View {
        VStack {
            if let url = Bundle.main.url(forResource: "sampleVideo", withExtension: "mp4") {
               
                        }
                        
                        Button(action: {
                            isProcessing = true
                            if let url = Bundle.main.url(forResource: "sampleVideo", withExtension: "mp4") {
                                viewModel.processVideo(url: url)
                            }
                        }, label: {
                            Text("Process Video")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        })
                        .padding()
                        
                        if isProcessing {
                            ProgressView("Processing...")
                                .padding()
                        }
        }
       
    }
    
}


