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
    @State private var showPracticeAll = false

    private var isReadingSubject: Bool {
        subject.name == L("subject.reading")
    }

    init(subject: Subject, viewModel: AppViewModel) {
        self.subject = subject
        self.viewModel = viewModel
        _topicsViewModel = StateObject(wrappedValue: TopicsViewModel(subject: subject, appViewModel: viewModel))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if !isReadingSubject {
                    practiceAllButton
                }
                ForEach(topicsViewModel.filteredTopics) { topic in
                    TopicCard(topic: topic, subjectName: subject.name) {
                        selectedTopic = topic
                    }
                    .contextMenu {
                        Button {
                            HapticFeedback.impact()
                            selectedTopic = topic
                        } label: {
                            Label(L("common.open"), systemImage: "arrow.right.circle")
                        }
                        Button {
                            HapticFeedback.impact()
                            topicsViewModel.setTopicToEdit(topic)
                        } label: {
                            Label(L("common.edit"), systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            HapticFeedback.impact()
                            topicsViewModel.setTopicToDelete(topic)
                        } label: {
                            Label(L("common.delete"), systemImage: "trash")
                        }
                    } preview: {
                        TopicPreviewCard(topic: topic, subjectName: subject.name)
                    }
                }
            }
            .padding()
        }
        .background(AppTheme.surface)
        .navigationTitle(subject.name)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: topicsViewModel.searchTextBinding, prompt: L("topics.search_placeholder"))
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
            if subject.name == L("subject.reading") {
                ReadingListScreen(topic: topic)
            } else {
                FlashcardListScreen(topic: topic, subject: subject, viewModel: viewModel)
            }
        }
        .navigationDestination(isPresented: $showPracticeAll) {
            PracticeAllScreen(subject: subject)
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
        .alert(L("topics.delete_title"), isPresented: Binding(
            get: { topicsViewModel.topicToDelete != nil },
            set: { if !$0 { topicsViewModel.clearTopicToDelete() } }
        )) {
            Button(L("common.cancel"), role: .cancel) {
                HapticFeedback.impact()
                topicsViewModel.clearTopicToDelete()
            }
            Button(L("common.delete"), role: .destructive) {
                HapticFeedback.impact()
                if let t = topicsViewModel.topicToDelete {
                    _ = topicsViewModel.deleteTopic(id: t.id)
                }
            }
        } message: {
            if let t = topicsViewModel.topicToDelete {
                Text(L("topics.delete_message", t.name))
            }
        }
    }

    private var practiceAllButton: some View {
        Button {
            HapticFeedback.impact()
            showPracticeAll = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("topics.practice_all"))
                        .fontWeight(.semibold)
                    Text(L("topics.practice_all_subtitle", subject.name))
                        .font(.caption)
                        .opacity(0.9)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
            }
            .padding(16)
            .foregroundStyle(.white)
            .background(AppTheme.heroGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(HapticButtonStyle())
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
                    TextField(L("topics.name_placeholder"), text: $name)
                        .focused($focused)
                }
            }
            .navigationTitle(L("topics.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("common.cancel")) {
                        HapticFeedback.impact()
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("common.save")) {
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
                    TextField(L("topics.name_placeholder"), text: $name)
                        .focused($focused)
                }
            }
            .navigationTitle(L("topics.edit_title"))
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
                    Image(systemName: "checkmark.seal.fill")
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

// MARK: - Topic Preview (long-press)

struct TopicPreviewCard: View {
    let topic: Topic
    let subjectName: String

    private var previewCards: [Flashcard] {
        Array(topic.flashcards.prefix(8))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: subjectName == "Bài đọc" ? "doc.text.fill" : "rectangle.stack.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(topic.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("\(topic.flashcards.count) \(subjectName == "Bài đọc" ? "bài" : "từ")")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            if !previewCards.isEmpty {
                Divider()
                ForEach(previewCards) { card in
                    HStack(spacing: 8) {
                        Text(card.questionDisplayText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        if let p = card.displayPhonetic, !p.isEmpty {
                            Text(p)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(card.answer)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
                if topic.flashcards.count > 8 {
                    Text("+ \(topic.flashcards.count - 8) từ khác...")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(AppTheme.cardBg)
    }
}
