//
//  SearchScreen.swift
//  FlashCardMobile
//

import SwiftUI

struct SearchResultItem: Identifiable, Hashable {
    let id: Int
    let flashcard: Flashcard
    let topic: Topic
    let subject: Subject
}

struct SearchScreen: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var searchText = ""
    @State private var selectedItem: SearchResultItem?
    @State private var results: [(Flashcard, Topic, Subject)] = []

    private var resultItems: [SearchResultItem] {
        results.map { SearchResultItem(id: $0.0.id, flashcard: $0.0, topic: $0.1, subject: $0.2) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.surface
                    .ignoresSafeArea()

                if searchText.isEmpty {
                    emptyState
                } else if results.isEmpty {
                    noResultsState
                } else {
                    resultsList
                }
            }
            .navigationTitle("Tìm từ vựng")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Tìm theo từ, nghĩa, gợi ý...")
            .onChange(of: searchText) { _, newValue in
                performSearch(query: newValue)
            }
            .navigationDestination(item: $selectedItem) { item in
                if let subject = viewModel.subjects.first(where: { $0.id == item.subject.id }),
                   let fullTopic = subject.topics.first(where: { $0.id == item.topic.id }) {
                    let listVM = FlashcardListViewModel(topic: fullTopic, subject: subject, appViewModel: viewModel)
                    FlashcardDetailScreen(flashcard: item.flashcard, listViewModel: listVM)
                }
            }
            .onAppear { viewModel.loadData() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
            Text("Tìm từ vựng")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Nhập từ khóa để tìm theo câu hỏi, đáp án, gợi ý hoặc phiên âm")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsState: some View {
        ContentUnavailableView.search(text: searchText)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(resultItems) { item in
                    SearchResultCard(item: item) {
                        selectedItem = item
                    }
                }
            }
            .padding()
        }
    }

    private func performSearch(query: String) {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty {
            results = []
        } else {
            results = DatabaseManager.shared.searchFlashcards(query: q)
        }
    }
}

struct SearchResultCard: View {
    let item: SearchResultItem
    let onTap: () -> Void

    var body: some View {
        Button {
            HapticFeedback.impact()
            onTap()
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.flashcard.questionDisplayText)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text(item.flashcard.answer)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text(item.topic.name)
                            .font(.caption)
                            .foregroundStyle(AppTheme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.primary.opacity(0.15))
                            .clipShape(Capsule())
                        Text(item.subject.name)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(16)
            .cardStyle()
        }
        .buttonStyle(HapticButtonStyle())
    }
}
