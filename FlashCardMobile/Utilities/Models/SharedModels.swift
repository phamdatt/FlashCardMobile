//
//  SharedModels.swift
//  FlashCardMobile
//

import Foundation

struct StreakInfo: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let didPracticeToday: Bool
}
