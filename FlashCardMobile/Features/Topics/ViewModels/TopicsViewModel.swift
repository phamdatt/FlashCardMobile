//
//  TopicsViewModel.swift
//  FlashCardMobile
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class TopicsViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var topicToEdit: Topic?
    @Published var topicToDelete: Topic?

    let subject: Subject
    private let appViewModel: AppViewModel
    private let db = DatabaseManager.shared

    var currentSubject: Subject? {
        appViewModel.subjects.first { $0.id == subject.id }
    }
    var topics: [Topic] {
        currentSubject?.topics ?? subject.topics
    }
    var filteredTopics: [Topic] {
        if searchText.isEmpty { return topics }
        return topics.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    init(subject: Subject, appViewModel: AppViewModel) {
        self.subject = subject
        self.appViewModel = appViewModel
    }

    func addTopic(name: String) -> Bool {
        guard let _ = db.insertTopic(subjectId: subject.id, name: name.trimmingCharacters(in: .whitespaces)) else { return false }
        appViewModel.loadData()
        return true
    }

    func updateTopic(id: Int, name: String) -> Bool {
        guard db.updateTopic(id: id, name: name.trimmingCharacters(in: .whitespaces)) else { return false }
        appViewModel.loadData()
        return true
    }

    func deleteTopic(id: Int) -> Bool {
        guard db.deleteTopic(id: id) else { return false }
        topicToDelete = nil
        appViewModel.loadData()
        return true
    }

    func clearTopicToEdit() { topicToEdit = nil }
    func setTopicToEdit(_ topic: Topic?) { topicToEdit = topic }
    func setTopicToDelete(_ topic: Topic?) { topicToDelete = topic }
    func clearTopicToDelete() { topicToDelete = nil }

    var searchTextBinding: Binding<String> {
        Binding(
            get: { self.searchText },
            set: { self.searchText = $0 }
        )
    }
}
