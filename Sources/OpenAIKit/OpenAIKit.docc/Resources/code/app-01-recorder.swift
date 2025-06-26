import SwiftUI
import AVFoundation
import OpenAIKit

// MARK: - Audio Recorder

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var recordings: [Recording] = []
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingSession = AVAudioSession.sharedInstance()
    private var timer: Timer?
    private var currentRecordingURL: URL?
    
    override init() {
        super.init()
        setupRecordingSession()
        loadRecordings()
    }
    
    private func setupRecordingSession() {
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            
            recordingSession.requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        print("Recording permission denied")
                    }
                }
            }
        } catch {
            print("Failed to set up recording session: \(error)")
        }
    }
    
    func startRecording() {
        let recordingURL = getNewRecordingURL()
        currentRecordingURL = recordingURL
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            isRecording = true
            recordingTime = 0
            
            // Start timer for recording time and level monitoring
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.updateRecordingStatus()
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        timer?.invalidate()
        timer = nil
        isRecording = false
        
        if let url = currentRecordingURL {
            let recording = Recording(
                id: UUID(),
                url: url,
                date: Date(),
                duration: recordingTime,
                name: "Recording \(recordings.count + 1)"
            )
            recordings.insert(recording, at: 0)
            saveRecordings()
        }
        
        currentRecordingURL = nil
        audioLevel = 0
    }
    
    func pauseRecording() {
        if isRecording {
            audioRecorder?.pause()
            timer?.invalidate()
        }
    }
    
    func resumeRecording() {
        if audioRecorder?.isRecording == false {
            audioRecorder?.record()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.updateRecordingStatus()
            }
        }
    }
    
    private func updateRecordingStatus() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        
        recordingTime = recorder.currentTime
        recorder.updateMeters()
        
        let normalizedLevel = normalizeLevel(recorder.averagePower(forChannel: 0))
        audioLevel = normalizedLevel
    }
    
    private func normalizeLevel(_ level: Float) -> Float {
        // Convert decibels to normalized value (0.0 to 1.0)
        let minDb: Float = -60
        let maxDb: Float = 0
        
        if level < minDb {
            return 0.0
        } else if level >= maxDb {
            return 1.0
        } else {
            return (level - minDb) / (maxDb - minDb)
        }
    }
    
    private func getNewRecordingURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        return documentsPath.appendingPathComponent(fileName)
    }
    
    func deleteRecording(_ recording: Recording) {
        do {
            try FileManager.default.removeItem(at: recording.url)
            recordings.removeAll { $0.id == recording.id }
            saveRecordings()
        } catch {
            print("Failed to delete recording: \(error)")
        }
    }
    
    func renameRecording(_ recording: Recording, to newName: String) {
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[index].name = newName
            saveRecordings()
        }
    }
    
    // MARK: - Persistence
    
    private func saveRecordings() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(recordings) {
            UserDefaults.standard.set(encoded, forKey: "recordings")
        }
    }
    
    private func loadRecordings() {
        if let data = UserDefaults.standard.data(forKey: "recordings"),
           let decoded = try? JSONDecoder().decode([Recording].self, from: data) {
            recordings = decoded.filter { recording in
                // Verify file still exists
                FileManager.default.fileExists(atPath: recording.url.path)
            }
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
        }
    }
}

// MARK: - Recording Model

struct Recording: Identifiable, Codable {
    let id: UUID
    let url: URL
    let date: Date
    let duration: TimeInterval
    var name: String
    var transcription: String?
    var isTranscribing: Bool = false
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Audio Player

class AudioPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    func play(_ recording: Recording) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording.url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            
            isPlaying = true
            duration = audioPlayer?.duration ?? 0
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.updatePlaybackStatus()
            }
        } catch {
            print("Failed to play recording: \(error)")
        }
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        timer?.invalidate()
    }
    
    func resume() {
        audioPlayer?.play()
        isPlaying = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updatePlaybackStatus()
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        currentTime = 0
        timer?.invalidate()
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    private func updatePlaybackStatus() {
        currentTime = audioPlayer?.currentTime ?? 0
        
        if currentTime >= duration {
            stop()
        }
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stop()
    }
}