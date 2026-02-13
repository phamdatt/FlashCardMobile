//
//  LearningModels.swift
//  FlashCardMobile
//

import Foundation

struct Subject: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let icon: String
    var topics: [Topic]

    var displayIcon: String {
        switch name {
        case "Tiếng Anh": return "globe.americas.fill"
        case "Tiếng Trung": return "text.book.closed.fill"
        case "Bài đọc": return "doc.richtext.fill"
        default: return icon
        }
    }
}

struct Topic: Identifiable, Hashable, Codable {
    var id: Int
    var name: String
    var subjectId: Int
    var flashcards: [Flashcard]
    var readings: [ReadingPassage]

    init(id: Int = 0, name: String, subjectId: Int, flashcards: [Flashcard], readings: [ReadingPassage] = []) {
        self.id = id
        self.name = name
        self.subjectId = subjectId
        self.flashcards = flashcards
        self.readings = readings
    }
}

struct ReadingPassage: Identifiable, Hashable, Codable {
    let id: Int
    let topicId: Int
    let title: String
    let content: String
    let createdAt: String
}

struct Flashcard: Identifiable, Hashable, Codable {
    static let exerciseTypeLabel = "Từ vựng"

    let id: Int
    let question: String
    let answer: String
    let hint: String?
    let options: [String]?
    let correctAnswer: String?
    let exerciseType: String
    let notes: String?
    let radical: String?
    let phonetic: String?

    var isMultipleChoice: Bool {
        options != nil && correctAnswer != nil
    }

    var questionDisplayText: String {
        let s = question.trimmingCharacters(in: .whitespaces)
        guard let lastClose = s.lastIndex(of: ")") else { return s }
        let beforeClose = s[..<lastClose]
        guard let lastOpen = beforeClose.lastIndex(of: "(") else { return s }
        return String(s[..<lastOpen]).trimmingCharacters(in: .whitespaces)
    }

    var pinyinFromQuestion: String? {
        let s = question.trimmingCharacters(in: .whitespaces)
        guard let lastClose = s.lastIndex(of: ")") else { return nil }
        let beforeClose = s[..<lastClose]
        guard let lastOpen = beforeClose.lastIndex(of: "(") else { return nil }
        return String(s[s.index(after: lastOpen)..<lastClose]).trimmingCharacters(in: .whitespaces)
    }

    var displayPhonetic: String? {
        if let p = phonetic, !p.isEmpty { return p }
        return pinyinFromQuestion
    }

    var questionDisplayTextWithPhonetic: String {
        guard let p = displayPhonetic, !p.isEmpty else { return questionDisplayText }
        return "\(questionDisplayText) (\(p))"
    }

    /// Chuỗi để sao chép: "Hán tự (pinyin) - nghĩa"
    var copyText: String {
        let q = questionDisplayTextWithPhonetic
        return "\(q) - \(answer)"
    }
}
