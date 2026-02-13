//
//  TopicsScreen.swift
//  FlashCardMobile
//

import SwiftUI

struct TopicsScreen: View {
    let subject: Subject
    @ObservedObject var viewModel: AppViewModel
    @StateObject private var topicsViewModel: TopicsViewModel
    @State private var selectedTopic: Topic?
    @State private var showAddTopic = false

    init(subject: Subject, viewModel: AppViewModel) {
        self.subject = subject
        self.viewModel = viewModel
        _topicsViewModel = StateObject(wrappedValue: TopicsViewModel(subject: subject, appViewModel: viewModel))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(topicsViewModel.filteredTopics) { topic in
                    TopicCard(topic: topic, subjectName: subject.name) {
                        selectedTopic = topic
                    }
                    .contextMenu {
                        Button {
                            HapticFeedback.impact()
                            topicsViewModel.setTopicToEdit(topic)
                        } label: {
                            Label("Sửa", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            HapticFeedback.impact()
                            topicsViewModel.setTopicToDelete(topic)
                        } label: {
                            Label("Xóa", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
        .background(AppTheme.surface)
        .navigationTitle(subject.name)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: topicsViewModel.searchTextBinding, prompt: "Tìm chủ đề")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 16) {
                    Button {
                        HapticFeedback.impact()
                        viewModel.selectedTabIndex = 2
                    } label: {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Button {
                        HapticFeedback.impact()
                        showAddTopic = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
        .navigationDestination(item: $selectedTopic) { topic in
            if subject.name == "Bài đọc" {
                ReadingListScreen(topic: topic)
            } else {
                FlashcardListScreen(topic: topic, subject: subject, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showAddTopic) {
            AddTopicSheet(viewModel: topicsViewModel, onDismiss: {
                showAddTopic = false
            })
        }
        .sheet(item: $topicsViewModel.topicToEdit) { t in
            EditTopicSheet(topic: t, viewModel: topicsViewModel, onDismiss: {
                topicsViewModel.clearTopicToEdit()
            })
        }
        .alert("Xóa chủ đề?", isPresented: Binding(
            get: { topicsViewModel.topicToDelete != nil },
            set: { if !$0 { topicsViewModel.clearTopicToDelete() } }
        )) {
            Button("Hủy", role: .cancel) {
                HapticFeedback.impact()
                topicsViewModel.clearTopicToDelete()
            }
            Button("Xóa", role: .destructive) {
                HapticFeedback.impact()
                if let t = topicsViewModel.topicToDelete {
                    _ = topicsViewModel.deleteTopic(id: t.id)
                }
            }
        } message: {
            if let t = topicsViewModel.topicToDelete {
                Text("Chủ đề \"\(t.name)\" và tất cả từ vựng sẽ bị xóa vĩnh viễn.")
            }
        }
    }
}

struct AddTopicSheet: View {
    @ObservedObject var viewModel: TopicsViewModel
    let onDismiss: () -> Void
    @State private var name = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Tên chủ đề", text: $name)
                        .focused($focused)
                }
            }
            .navigationTitle("Thêm chủ đề")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") {
                        HapticFeedback.impact()
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        HapticFeedback.impact()
                        if viewModel.addTopic(name: name) {
                            onDismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { focused = true }
        }
    }
}

struct EditTopicSheet: View {
    let topic: Topic
    @ObservedObject var viewModel: TopicsViewModel
    let onDismiss: () -> Void
    @State private var name = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Tên chủ đề", text: $name)
                        .focused($focused)
                }
            }
            .navigationTitle("Sửa chủ đề")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") {
                        HapticFeedback.impact()
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        HapticFeedback.impact()
                        if viewModel.updateTopic(id: topic.id, name: name) {
                            onDismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = topic.name
                focused = true
            }
        }
    }
}

struct TopicCard: View {
    let topic: Topic
    let subjectName: String
    let onTap: () -> Void

    private var cardCount: Int {
        topic.flashcards.count
    }

    private var hasPractice: Bool {
        DatabaseManager.shared.getPracticeSessionCount(topicId: topic.id) > 0
    }

    var body: some View {
        Button {
            HapticFeedback.impact()
            onTap()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppTheme.surface)
                        .frame(width: 48, height: 48)
                    Image(systemName: subjectName == "Bài đọc" ? "doc.text" : "rectangle.stack.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(topic.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("\(cardCount) \(subjectName == "Bài đọc" ? "bài" : "từ")")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                if hasPractice {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accentGreen)
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(16)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}
