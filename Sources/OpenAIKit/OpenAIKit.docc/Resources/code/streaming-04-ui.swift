// ResearchView.swift
import SwiftUI
import OpenAIKit

struct ResearchView: View {
    @StateObject private var viewModel = StreamingResearchViewModel(
        apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    )
    @State private var query = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Search input
                HStack {
                    TextField("Enter your research query...", text: $query)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(viewModel.isLoading)
                    
                    Button(action: { 
                        if !query.isEmpty {
                            viewModel.performResearch(query: query)
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(viewModel.isLoading || query.isEmpty)
                }
                .padding(.horizontal)
                
                // Progress indicator
                if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        
                        Text(viewModel.researchProgress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 30) {
                            Label("\(viewModel.searchCount)", systemImage: "globe")
                            Label("\(viewModel.reasoningCount)", systemImage: "brain")
                        }
                        .font(.caption)
                        
                        Button("Cancel") {
                            viewModel.cancelResearch()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    .padding()
                }
                
                // Results
                if !viewModel.finalContent.isEmpty {
                    ScrollView {
                        Text(viewModel.finalContent)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Error display
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("DeepResearch")
        }
    }
}