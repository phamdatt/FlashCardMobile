//
//  AppViewModel.swift
//  FlashCardMobile
//

import Foundation
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published var subjects: [Subject] = []
    @Published var streakInfo: StreakInfo = StreakInfo(currentStreak: 0, longestStreak: 0, didPracticeToday: false)
    @Published var isLoading = false
    /// Tab index: 0=Học, 1=Ôn tập, 2=Tìm kiếm, 3=Thống kê, 4=Cài đặt
    @Published var selectedTabIndex: Int = 0

    private let db = DatabaseManager.shared

    func loadData() {
        isLoading = true
        subjects = db.loadAllSubjects()
        streakInfo = db.getStreakInfo()
        isLoading = false
    }

    func refreshStreak() {
        streakInfo = db.getStreakInfo()
    }
}
