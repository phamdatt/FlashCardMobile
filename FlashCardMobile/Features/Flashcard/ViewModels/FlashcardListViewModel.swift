//
//  FlashcardListViewModel.swift
//  FlashCardMobile
//

import Foundation
import Combine

enum PracticeType: String, CaseIterable {
    case flipCard = "flip_card"
    case multipleChoice = "multiple_choice"
    case listening = "listening"
    case meaningToHanzi = "meaning_to_hanzi"

    static let similarVocabKey = "similar_vocab"
    static let randomDailyKey = "random_daily"
    static let mistakesKey = "frequently_wrong"

    var displayName: String {
        switch self {
        case .flipCard: return L("practice_type.flip_card")
        case .multipleChoice: return L("practice_type.multiple_choice")
        case .listening: return L("practice_type.listening")
        case .meaningToHanzi: return L("practice_type.meaning_to_hanzi")
        }
    }

    var descriptionText: String {
        switch self {
        case .flipCard: return L("practice_type.flip_desc")
        case .multipleChoice: return L("practice_type.mc_desc")
        case .listening: return L("practice_type.listen_desc")
        case .meaningToHanzi: return L("practice_type.hanzi_desc")
        }
    }

    static func availableTypes(subjectName: String?) -> [PracticeType] {
        let base: [PracticeType] = [.multipleChoice, .listening]
        if subjectName == "Tiếng Trung" {
            return base + [.meaningToHanzi]
        }
        return base
    }
}

@MainActor
final class FlashcardListViewModel: ObservableObject {
    @Published var flashcardToEdit: Flashcard?
    @Published var flashcardToDelete: Flashcard?

    let topic: Topic
    let subject: Subject
    private let appViewModel: AppViewModel
    private let db = DatabaseManager.shared

    var currentTopic: Topic? {
        appViewModel.subjects.first { $0.id == subject.id }?.topics.first { $0.id == topic.id }
    }
    var flashcards: [Flashcard] {
        currentTopic?.flashcards ?? topic.flashcards
    }
    var topicForPractice: Topic {
        Topic(id: topic.id, name: topic.name, subjectId: subject.id, flashcards: flashcards, readings: topic.readings)
    }

    init(topic: Topic, subject: Subject, appViewModel: AppViewModel) {
        self.topic = topic
        self.subject = subject
        self.appViewModel = appViewModel
    }

    func addFlashcard(question: String, answer: String, hint: String?, notes: String?, radical: String?, phonetic: String?) -> Bool {
        let q = question.trimmingCharacters(in: .whitespaces)
        let a = answer.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty, !a.isEmpty else { return false }
        guard db.insertFlashcard(
            topicId: topic.id,
            question: q,
            answer: a,
            hint: hint,
            notes: notes,
            radical: radical,
            phonetic: phonetic
        ) != nil else { return false }
        appViewModel.loadData()
        return true
    }

    func updateFlashcard(id: Int, question: String, answer: String, hint: String?, notes: String?, radical: String?, phonetic: String?) -> Bool {
        let q = question.trimmingCharacters(in: .whitespaces)
        let a = answer.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty, !a.isEmpty else { return false }
        guard db.updateFlashcard(id: id, question: q, answer: a, hint: hint, notes: notes, radical: radical, phonetic: phonetic) else { return false }
        flashcardToEdit = nil
        appViewModel.loadData()
        return true
    }

    func deleteFlashcard(id: Int) -> Bool {
        guard db.deleteFlashcard(id: id) else { return false }
        flashcardToDelete = nil
        appViewModel.loadData()
        return true
    }

    func refreshAfterImport() {
        appViewModel.loadData()
    }

    func setFlashcardToEdit(_ card: Flashcard?) { flashcardToEdit = card }
    func setFlashcardToDelete(_ card: Flashcard?) { flashcardToDelete = card }
    func clearFlashcardToEdit() { flashcardToEdit = nil }
    func clearFlashcardToDelete() { flashcardToDelete = nil }
}
