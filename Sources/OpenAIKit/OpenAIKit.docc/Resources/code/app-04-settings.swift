import SwiftUI
import OpenAIKit

// MARK: - Settings View

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var showingAPIKeyInput = false
    @State private var apiKeyInput = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // API Configuration
                Section {
                    HStack {
                        Text("API Key")
                        Spacer()
                        if settings.hasAPIKey {
                            Text("Configured")
                                .foregroundColor(.green)
                        } else {
                            Text("Not Set")
                                .foregroundColor(.red)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingAPIKeyInput = true
                    }
                    
                    Picker("Model", selection: $settings.selectedModel) {
                        ForEach(WhisperModel.allCases, id: \.self) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                } header: {
                    Text("OpenAI Configuration")
                } footer: {
                    Text("Your API key is stored securely in the device keychain")
                }
                
                // Audio Settings
                Section("Audio Settings") {
                    Picker("Audio Quality", selection: $settings.audioQuality) {
                        ForEach(AudioQuality.allCases, id: \.self) { quality in
                            Text(quality.displayName).tag(quality)
                        }
                    }
                    
                    Picker("Sample Rate", selection: $settings.sampleRate) {
                        ForEach(SampleRate.allCases, id: \.self) { rate in
                            Text(rate.displayName).tag(rate)
                        }
                    }
                    
                    Toggle("Noise Reduction", isOn: $settings.enableNoiseReduction)
                    
                    Slider(value: $settings.silenceThreshold, in: -60...0) {
                        Text("Silence Threshold")
                    }
                    Text("Threshold: \(Int(settings.silenceThreshold)) dB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Transcription Settings
                Section("Transcription Defaults") {
                    Picker("Default Language", selection: $settings.defaultLanguage) {
                        Text("Auto Detect").tag(nil as WhisperLanguage?)
                        ForEach(settings.favoriteLanguages, id: \.self) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.displayName)
                            }
                            .tag(language as WhisperLanguage?)
                        }
                    }
                    
                    Toggle("Include Timestamps", isOn: $settings.includeTimestamps)
                    Toggle("Include Punctuation", isOn: $settings.includePunctuation)
                    
                    HStack {
                        Text("Temperature")
                        Slider(value: $settings.defaultTemperature, in: 0...1)
                            .frame(width: 150)
                        Text("\(settings.defaultTemperature, specifier: "%.1f")")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Storage Settings
                Section("Storage") {
                    HStack {
                        Text("Storage Used")
                        Spacer()
                        Text(formatBytes(settings.storageUsed))
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Auto-Delete Old Recordings", isOn: $settings.autoDeleteOldRecordings)
                    
                    if settings.autoDeleteOldRecordings {
                        Picker("Keep Recordings For", selection: $settings.recordingRetentionDays) {
                            Text("7 days").tag(7)
                            Text("30 days").tag(30)
                            Text("90 days").tag(90)
                            Text("1 year").tag(365)
                        }
                    }
                    
                    Button("Clear All Recordings", role: .destructive) {
                        clearAllRecordings()
                    }
                }
                
                // Export/Import
                Section("Data Management") {
                    Button("Export All Transcriptions") {
                        exportTranscriptions()
                    }
                    
                    Button("Backup Settings") {
                        backupSettings()
                    }
                    
                    Button("Restore Settings") {
                        restoreSettings()
                    }
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                    Link("Support", destination: URL(string: "https://example.com/support")!)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAPIKeyInput) {
                APIKeyInputView(apiKey: $apiKeyInput) { key in
                    settings.setAPIKey(key)
                    showingAPIKeyInput = false
                }
            }
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func clearAllRecordings() {
        // Implementation to clear all recordings
    }
    
    private func exportTranscriptions() {
        // Implementation to export transcriptions
    }
    
    private func backupSettings() {
        // Implementation to backup settings
    }
    
    private func restoreSettings() {
        // Implementation to restore settings
    }
}

// MARK: - App Settings

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var hasAPIKey: Bool = false
    @Published var selectedModel: WhisperModel = .whisper1
    @Published var audioQuality: AudioQuality = .high
    @Published var sampleRate: SampleRate = .rate44100
    @Published var enableNoiseReduction: Bool = true
    @Published var silenceThreshold: Double = -40
    @Published var defaultLanguage: WhisperLanguage?
    @Published var favoriteLanguages: [WhisperLanguage] = [.english, .spanish, .french]
    @Published var includeTimestamps: Bool = false
    @Published var includePunctuation: Bool = true
    @Published var defaultTemperature: Double = 0
    @Published var autoDeleteOldRecordings: Bool = false
    @Published var recordingRetentionDays: Int = 30
    @Published var storageUsed: Int64 = 0
    
    private let keychain = KeychainManager()
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSettings()
        calculateStorageUsed()
    }
    
    func setAPIKey(_ key: String) {
        keychain.save(key: "openai_api_key", value: key)
        hasAPIKey = !key.isEmpty
    }
    
    func getAPIKey() -> String? {
        keychain.get(key: "openai_api_key")
    }
    
    private func loadSettings() {
        hasAPIKey = getAPIKey() != nil
        
        if let modelRaw = userDefaults.string(forKey: "selectedModel"),
           let model = WhisperModel(rawValue: modelRaw) {
            selectedModel = model
        }
        
        if let qualityRaw = userDefaults.string(forKey: "audioQuality"),
           let quality = AudioQuality(rawValue: qualityRaw) {
            audioQuality = quality
        }
        
        // Load other settings...
    }
    
    private func calculateStorageUsed() {
        // Calculate total storage used by recordings
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: [.fileSizeKey])
            
            storageUsed = files.reduce(0) { total, url in
                let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                return total + Int64(fileSize)
            }
        } catch {
            print("Failed to calculate storage: \(error)")
        }
    }
}

// MARK: - Enums

enum WhisperModel: String, CaseIterable {
    case whisper1 = "whisper-1"
    
    var displayName: String {
        switch self {
        case .whisper1:
            return "Whisper v1"
        }
    }
}

enum AudioQuality: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low:
            return "Low (Smaller files)"
        case .medium:
            return "Medium"
        case .high:
            return "High (Better quality)"
        }
    }
    
    var bitRate: Int {
        switch self {
        case .low:
            return 64000
        case .medium:
            return 128000
        case .high:
            return 256000
        }
    }
}

enum SampleRate: String, CaseIterable {
    case rate22050 = "22050"
    case rate44100 = "44100"
    case rate48000 = "48000"
    
    var displayName: String {
        switch self {
        case .rate22050:
            return "22.05 kHz"
        case .rate44100:
            return "44.1 kHz"
        case .rate48000:
            return "48 kHz"
        }
    }
    
    var value: Double {
        switch self {
        case .rate22050:
            return 22050
        case .rate44100:
            return 44100
        case .rate48000:
            return 48000
        }
    }
}

// MARK: - API Key Input View

struct APIKeyInputView: View {
    @Binding var apiKey: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("API Key", text: $apiKey)
                        .textContentType(.password)
                } header: {
                    Text("Enter your OpenAI API Key")
                } footer: {
                    Text("You can find your API key at platform.openai.com")
                }
            }
            .navigationTitle("API Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(apiKey)
                    }
                    .disabled(apiKey.isEmpty)
                }
            }
        }
    }
}

// MARK: - Keychain Manager

class KeychainManager {
    func save(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
}