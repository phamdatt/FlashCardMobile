//
//  SpeechManager.swift
//  FlashCardMobile
//

import Foundation
import AVFoundation
import Combine
import SwiftUI

@MainActor
final class SpeechManager: ObservableObject {
    static let shared = SpeechManager()

    private let synthesizer = AVSpeechSynthesizer()
    private var delegateHolder: SpeechDelegateHolder?

    @Published private(set) var isSpeaking = false
    @Published var ttsUnavailableMessage: String?

    private init() {
        let holder = SpeechDelegateHolder()
        synthesizer.delegate = holder
        self.delegateHolder = holder
        holder.onFinish = { [weak self] in
            Task { @MainActor in
                self?.isSpeaking = false
            }
        }
    }

    func speak(text: String, language: String? = nil) {
        ttsUnavailableMessage = nil
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let lang = language ?? detectLanguage(t)
        let voice = voiceForLanguage(lang)
        guard let voice = voice else {
            ttsUnavailableMessage = "Chưa có giọng đọc. Vào Cài đặt → Trợ năng → Nội dung đọc để tải giọng."
            return
        }
        let utterance = AVSpeechUtterance(string: t)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.voice = voice
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    private func voiceForLanguage(_ language: String) -> AVSpeechSynthesisVoice? {
        if language.hasPrefix("zh") {
            let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("zh") }
            if !voices.isEmpty {
                if let male = voices.first(where: { $0.gender == .male }) { return male }
                return voices.first
            }
            return AVSpeechSynthesisVoice(language: language)
        }
        return AVSpeechSynthesisVoice(language: language)
            ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func detectLanguage(_ text: String) -> String {
        let cjk = text.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF }
        if cjk { return "zh-CN" }
        return "en-US"
    }
}

private final class SpeechDelegateHolder: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: (() -> Void)?
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinish?()
    }
}
