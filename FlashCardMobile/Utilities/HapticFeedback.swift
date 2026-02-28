//
//  HapticFeedback.swift
//  FlashCardMobile
//

import SwiftUI
import UIKit
import AVFoundation

enum HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

/// ButtonStyle that adds haptic on press. Use instead of .plain for tappable buttons.
struct HapticButtonStyle: ButtonStyle {
    var style: UIImpactFeedbackGenerator.FeedbackStyle = .light

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, new in
                if new {
                    HapticFeedback.impact(style)
                }
            }
    }
}

// MARK: - Sound Effects (Duolingo-style custom tones)

enum SoundEffect {
    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "sound_effects_enabled") as? Bool ?? true
    }

    private static let tonePlayer = TonePlayer()

    /// Ascending two-note chime for correct answers (C5 → E5)
    static func playCorrect() {
        guard isEnabled else { return }
        tonePlayer.play(notes: [
            (frequency: 523.25, duration: 0.1, delay: 0.0),     // C5
            (frequency: 659.25, duration: 0.15, delay: 0.1),    // E5
        ], volume: 0.35)
        HapticFeedback.notification(.success)
    }

    /// Low descending tone for wrong answers (Eb4 → C4)
    static func playWrong() {
        guard isEnabled else { return }
        tonePlayer.play(notes: [
            (frequency: 311.13, duration: 0.12, delay: 0.0),    // Eb4
            (frequency: 261.63, duration: 0.2, delay: 0.1),     // C4
        ], volume: 0.28)
        HapticFeedback.notification(.error)
    }

    /// Ascending arpeggio fanfare for completing a session (C5 → E5 → G5 → C6)
    static func playComplete() {
        guard isEnabled else { return }
        tonePlayer.play(notes: [
            (frequency: 523.25, duration: 0.12, delay: 0.0),    // C5
            (frequency: 659.25, duration: 0.12, delay: 0.13),   // E5
            (frequency: 783.99, duration: 0.12, delay: 0.26),   // G5
            (frequency: 1046.50, duration: 0.3, delay: 0.39),   // C6
        ], volume: 0.35)
        HapticFeedback.notification(.success)
    }
}

// MARK: - Tone Player (generates musical tones via AVAudioPlayer)

private final class TonePlayer {
    private var audioPlayer: AVAudioPlayer?
    private let sampleRate: Double = 44100
    private let queue = DispatchQueue(label: "com.flashcard.toneplayer", qos: .userInitiated)

    typealias NoteSpec = (frequency: Double, duration: Double, delay: Double)

    init() {
        // Configure audio session once on init (called lazily on first use)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func play(notes: [NoteSpec], volume: Float) {
        queue.async { [weak self] in
            guard let self else { return }

            let totalDuration = notes.map { $0.delay + $0.duration }.max() ?? 0.5
            let totalFrames = Int(totalDuration * self.sampleRate)

            // Generate combined waveform
            var samples = [Float](repeating: 0, count: totalFrames)

            for note in notes {
                let startFrame = Int(note.delay * self.sampleRate)
                let noteFrames = Int(note.duration * self.sampleRate)
                let omega = 2.0 * Double.pi * note.frequency / self.sampleRate

                for i in 0..<noteFrames {
                    let idx = startFrame + i
                    guard idx < totalFrames else { break }

                    let t = Double(i)
                    let pos = Double(i) / Double(noteFrames)

                    // Envelope: quick attack, smooth decay
                    let attack = min(pos * 25, 1.0)
                    let decay = pow(1.0 - pos, 1.5)
                    let envelope = Float(attack * decay)

                    // Fundamental + harmonics for warm bell-like tone
                    let wave = Float(
                        sin(omega * t)
                        + sin(omega * 2.0 * t) * 0.25
                        + sin(omega * 3.0 * t) * 0.08
                    )

                    samples[idx] += wave * volume * envelope
                }
            }

            // Clamp
            for i in samples.indices {
                samples[i] = max(-1.0, min(1.0, samples[i]))
            }

            guard let wavData = self.createWAV(samples: samples, sampleRate: Int(self.sampleRate)) else { return }

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                // Re-activate session in case it was interrupted (e.g. by SpeechManager)
                try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                self.audioPlayer?.stop()
                self.audioPlayer = try? AVAudioPlayer(data: wavData)
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
            }
        }
    }

    private func createWAV(samples: [Float], sampleRate: Int) -> Data? {
        let bitsPerSample: Int16 = 16
        let channels: Int16 = 1
        let bytesPerSample = Int(bitsPerSample) / 8
        let dataSize = samples.count * bytesPerSample
        let fileSize = 36 + dataSize

        var data = Data()

        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: Int32(fileSize).littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)

        // fmt chunk
        data.append(contentsOf: "fmt ".utf8)
        data.append(contentsOf: withUnsafeBytes(of: Int32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: Int16(1).littleEndian) { Array($0) })       // PCM
        data.append(contentsOf: withUnsafeBytes(of: channels.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: Int32(sampleRate).littleEndian) { Array($0) })
        let byteRate = Int32(sampleRate * Int(channels) * bytesPerSample)
        data.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        let blockAlign = Int16(Int(channels) * bytesPerSample)
        data.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) })

        // data chunk
        data.append(contentsOf: "data".utf8)
        data.append(contentsOf: withUnsafeBytes(of: Int32(dataSize).littleEndian) { Array($0) })

        for sample in samples {
            let intSample = Int16(max(-1, min(1, sample)) * Float(Int16.max))
            data.append(contentsOf: withUnsafeBytes(of: intSample.littleEndian) { Array($0) })
        }

        return data
    }
}
