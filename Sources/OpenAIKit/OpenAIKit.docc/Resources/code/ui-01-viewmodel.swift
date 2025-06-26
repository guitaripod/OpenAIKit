// ImageGenerationViewModel.swift
import Foundation
import OpenAIKit
import SwiftUI

@MainActor
class ImageGenerationViewModel: ObservableObject {
    @Published var prompt = ""
    @Published var generatedImageURL: URL?
    @Published var isGenerating = false
    @Published var error: Error?
    @Published var options = ImageGenerationOptions.standard
    
    private let openAI: OpenAIKit
    
    init(openAI: OpenAIKit) {
        self.openAI = openAI
    }
    
    func generateImage() async {
        guard !prompt.isEmpty else { return }
        
        isGenerating = true
        error = nil
        
        do {
            let request = options.createRequest(prompt: prompt)
            let response = try await openAI.images.generations(request)
            
            if let urlString = response.data.first?.url,
               let url = URL(string: urlString) {
                generatedImageURL = url
            }
        } catch {
            self.error = error
        }
        
        isGenerating = false
    }
}
