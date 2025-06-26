import SwiftUI
import AVFoundation
import OpenAIKit

// MARK: - Audio Playback View

struct AudioPlaybackView: View {
    let recording: Recording
    @StateObject private var player = EnhancedAudioPlayer()
    @State private var showingWaveform = true
    @State private var showingTranscript = false
    @State private var selectedSegment: TranscriptionSegment?
    
    var body: some View {
        VStack(spacing: 0) {
            // Playback Controls
            PlaybackControlsView(player: player, recording: recording)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
            
            // View Toggle
            Picker("View Mode", selection: $showingWaveform) {
                Text("Waveform").tag(true)
                Text("Transcript").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Content Area
            if showingWaveform {
                WaveformView(
                    audioURL: recording.url,
                    currentTime: player.currentTime,
                    duration: player.duration,
                    onSeek: { time in
                        player.seek(to: time)
                    }
                )
                .padding()
            } else {
                TranscriptPlaybackView(
                    recording: recording,
                    currentTime: player.currentTime,
                    onSegmentTap: { segment in
                        if let startTime = segment.start {
                            player.seek(to: startTime)
                        }
                    }
                )
            }
            
            // Timeline
            TimelineView(
                currentTime: player.currentTime,
                duration: player.duration,
                isPlaying: player.isPlaying,
                onSeek: player.seek
            )
            .padding()
        }
        .navigationTitle(recording.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            player.load(recording.url)
        }
        .onDisappear {
            player.stop()
        }
    }
}

// MARK: - Enhanced Audio Player

class EnhancedAudioPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    @Published var volume: Float = 1.0
    
    private var audioPlayer: AVAudioPlayer?
    private var displayLink: CADisplayLink?
    private var audioSession = AVAudioSession.sharedInstance()
    
    func load(_ url: URL) {
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.enableRate = true
            
            duration = audioPlayer?.duration ?? 0
            volume = audioPlayer?.volume ?? 1.0
        } catch {
            print("Failed to load audio: \(error)")
        }
    }
    
    func play() {
        audioPlayer?.play()
        isPlaying = true
        startDisplayLink()
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopDisplayLink()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        currentTime = 0
        isPlaying = false
        stopDisplayLink()
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        audioPlayer?.rate = rate
    }
    
    func setVolume(_ volume: Float) {
        self.volume = volume
        audioPlayer?.volume = volume
    }
    
    func skipForward(_ seconds: TimeInterval = 15) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    func skipBackward(_ seconds: TimeInterval = 15) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updatePlaybackTime))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updatePlaybackTime() {
        currentTime = audioPlayer?.currentTime ?? 0
    }
}

extension EnhancedAudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stop()
    }
}

// MARK: - Playback Controls View

struct PlaybackControlsView: View {
    @ObservedObject var player: EnhancedAudioPlayer
    let recording: Recording
    
    var body: some View {
        VStack(spacing: 20) {
            // Time Display
            HStack {
                Text(formatTime(player.currentTime))
                    .font(.system(.body, design: .monospaced))
                
                Spacer()
                
                Text(formatTime(player.duration))
                    .font(.system(.body, design: .monospaced))
            }
            .foregroundColor(.secondary)
            
            // Main Controls
            HStack(spacing: 40) {
                // Skip Backward
                Button(action: { player.skipBackward() }) {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                }
                
                // Play/Pause
                Button(action: togglePlayback) {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                }
                
                // Skip Forward
                Button(action: { player.skipForward() }) {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                }
            }
            
            // Speed Control
            HStack {
                Text("Speed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                    Button(action: { player.setPlaybackRate(Float(speed)) }) {
                        Text("\(speed, specifier: "%.2g")x")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                player.playbackRate == Float(speed) ?
                                Color.blue : Color(UIColor.tertiarySystemBackground)
                            )
                            .foregroundColor(
                                player.playbackRate == Float(speed) ? .white : .primary
                            )
                            .cornerRadius(6)
                    }
                }
            }
            
            // Volume Control
            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundColor(.secondary)
                
                Slider(value: $player.volume, in: 0...1) { _ in
                    player.setVolume(player.volume)
                }
                
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func togglePlayback() {
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Waveform View

struct WaveformView: View {
    let audioURL: URL
    let currentTime: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void
    
    @State private var waveformData: [Float] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Waveform bars
                HStack(spacing: 2) {
                    ForEach(0..<waveformData.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(barColor(for: index, width: geometry.size.width))
                            .frame(width: max(1, (geometry.size.width / CGFloat(waveformData.count)) - 2))
                            .scaleEffect(y: CGFloat(waveformData[index]), anchor: .center)
                    }
                }
                
                // Progress overlay
                if duration > 0 {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: geometry.size.width * CGFloat(currentTime / duration))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                let progress = location.x / geometry.size.width
                let seekTime = duration * Double(progress)
                onSeek(seekTime)
            }
        }
        .frame(height: 100)
        .onAppear {
            generateWaveform()
        }
    }
    
    private func barColor(for index: Int, width: CGFloat) -> Color {
        let progress = duration > 0 ? currentTime / duration : 0
        let barProgress = Double(index) / Double(waveformData.count)
        
        return barProgress <= progress ? Color.blue : Color.gray.opacity(0.3)
    }
    
    private func generateWaveform() {
        // Generate mock waveform data
        // In a real app, you'd analyze the audio file
        waveformData = (0..<100).map { _ in
            Float.random(in: 0.1...1.0)
        }
    }
}

// MARK: - Timeline View

struct TimelineView: View {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let isPlaying: Bool
    let onSeek: (TimeInterval) -> Void
    
    @State private var isDragging = false
    @State private var dragTime: TimeInterval = 0
    
    var displayTime: TimeInterval {
        isDragging ? dragTime : currentTime
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(displayTime / max(duration, 1)), height: 4)
                    
                    // Thumb
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                        .position(
                            x: geometry.size.width * CGFloat(displayTime / max(duration, 1)),
                            y: geometry.size.height / 2
                        )
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            let progress = value.location.x / geometry.size.width
                            dragTime = duration * Double(max(0, min(1, progress)))
                        }
                        .onEnded { _ in
                            onSeek(dragTime)
                            isDragging = false
                        }
                )
            }
            .frame(height: 12)
            
            // Time Labels
            HStack {
                Text(formatTime(displayTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("-\(formatTime(duration - displayTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Transcript Playback View

struct TranscriptPlaybackView: View {
    let recording: Recording
    let currentTime: TimeInterval
    let onSegmentTap: (TranscriptionSegment) -> Void
    
    @State private var segments: [TranscriptionSegment] = []
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let transcription = recording.transcription {
                        if segments.isEmpty {
                            // Full transcript without timestamps
                            Text(transcription)
                                .font(.body)
                                .padding()
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(8)
                        } else {
                            // Segmented transcript with timestamps
                            ForEach(segments) { segment in
                                SegmentView(
                                    segment: segment,
                                    isActive: isSegmentActive(segment),
                                    onTap: { onSegmentTap(segment) }
                                )
                                .id(segment.id)
                            }
                        }
                    } else {
                        Text("No transcription available")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .onChange(of: currentTime) { _ in
                if let activeSegment = segments.first(where: { isSegmentActive($0) }) {
                    withAnimation {
                        proxy.scrollTo(activeSegment.id, anchor: .center)
                    }
                }
            }
        }
    }
    
    private func isSegmentActive(_ segment: TranscriptionSegment) -> Bool {
        guard let start = segment.start, let end = segment.end else { return false }
        return currentTime >= start && currentTime < end
    }
}

struct SegmentView: View {
    let segment: TranscriptionSegment
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timestamp
            if let start = segment.start {
                Text(formatTime(start))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }
            
            // Text
            Text(segment.text)
                .font(.body)
                .foregroundColor(isActive ? .primary : .secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.blue.opacity(0.1) : Color(UIColor.tertiarySystemBackground))
        )
        .onTapGesture(perform: onTap)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}