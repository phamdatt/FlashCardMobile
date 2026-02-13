//
//  StatisticsViewModel.swift
//  FlashCardMobile
//

import Foundation
import Combine

@MainActor
final class StatisticsViewModel: ObservableObject {
    private let appViewModel: AppViewModel
    private let db = DatabaseManager.shared

    var subjects: [Subject] { appViewModel.subjects }
    var streakInfo: StreakInfo { appViewModel.streakInfo }
    var totalCards: Int {
        appViewModel.subjects.reduce(0) { $0 + $1.topics.reduce(0) { $0 + $1.flashcards.count } }
    }
    var dueCount: Int { db.getDueFlashcards().count }

    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
    }

    func loadData() {
        appViewModel.loadData()
    }
}
