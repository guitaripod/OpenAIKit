import SwiftUI
import OpenAIKit

struct ChatView: View {
    @State private var response: String = ""
    
    var body: some View {
        Text(response.isEmpty ? "Hello, World!" : response)
    }
}