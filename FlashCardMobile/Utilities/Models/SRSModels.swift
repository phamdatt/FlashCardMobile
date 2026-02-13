//
//  SRSModels.swift
//  FlashCardMobile
//

import Foundation

struct FlashcardProgress: Identifiable, Codable {
    let id: Int
    let flashcardId: Int
    var easeFactor: Double
    var interval: Int
    var repetitions: Int
    var nextReviewDate: Date
    var lastReviewDate: Date?
    var difficulty: Double
    var totalReviews: Int
    var correctReviews: Int
    var incorrectReviews: Int

    var accuracy: Double {
        guard totalReviews > 0 else { return 0.0 }
        return Double(correctReviews) / Double(totalReviews)
    }
}
