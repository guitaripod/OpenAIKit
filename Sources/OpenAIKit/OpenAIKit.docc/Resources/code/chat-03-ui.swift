// ChatExample.swift
import Foundation
import OpenAIKit
import SwiftUI

struct ChatView: View {
    @State private var userMessage = ""
    @State private var messages: [String] = []
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach(messages, id: \.self) { message in
                    Text(message)
                        .padding()
                }
            }
            
            HStack {
                TextField("Type a message", text: $userMessage)
                Button("Send") {
                    // Send message
                }
            }
            .padding()
        }
    }
}