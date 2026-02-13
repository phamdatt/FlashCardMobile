//
//  PracticeAllScreen.swift
//  FlashCardMobile
//

import SwiftUI

struct PracticeAllScreen: View {
    let subject: Subject
    let topic: Topic?

    init(subject: Subject, topic: Topic? = nil) {
        self.subject = subject
        self.topic = topic
    }

    @Environment(\.dismiss) private var dismiss
    @State private var practiceType: PracticeType = .flipCard
    @State private var showFlipPractice = false
    @State private var showMultipleChoicePractice = false
    @State private var showListeningPractice = false
    @State private var showMeaningToHanziPractice = false
    @State private var selectedLimit: Int = 20
    @State private var loadedCards: [Flashcard] = []
    @State private var totalCardCount: Int = 0
    @State private var isLoading = true

    private let limitOptions: [Int] = [20, 30, 40, 50, 0]

    private var practiceTopic: Topic {
        let cards = loadedCards
        if let topic = topic {
            return Topic(id: topic.id, name: topic.name, subjectId: subject.id, flashcards: cards)
        }
        return Topic(id: -1, name: "Tất cả \(subject.name)", subjectId: subject.id, flashcards: cards)
    }

    private var availableTypes: [PracticeType] {
        PracticeType.availableTypes(subjectName: subject.name)
    }

    var body: some View {
        Group {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView("Đang tải từ vựng...")
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        headerCard

                        limitPicker

                        Text("Chọn kiểu luyện tập")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(availableTypes, id: \.self) { type in
                            PracticeTypeCard(type: type) {
                                HapticFeedback.impact()
                                practiceType = type
                                switch type {
                                case .flipCard: showFlipPractice = true
                                case .multipleChoice: showMultipleChoicePractice = true
                                case .listening: showListeningPractice = true
                                case .meaningToHanzi: showMeaningToHanziPractice = true
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(AppTheme.surface)
        .navigationTitle(topic != nil ? "Luyện tập" : "Luyện tập tất cả")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCards()
        }
        .onChange(of: selectedLimit) { _, newLimit in
            Task { await loadCards(limit: newLimit) }
        }
        .fullScreenCover(isPresented: $showFlipPractice) {
            FlipCardPracticeScreen(topic: practiceTopic, subject: subject)
        }
        .fullScreenCover(isPresented: $showMultipleChoicePractice) {
            MultipleChoicePracticeScreen(topic: practiceTopic, subject: subject)
        }
        .fullScreenCover(isPresented: $showListeningPractice) {
            ListeningPracticeScreen(topic: practiceTopic, subject: subject)
        }
        .fullScreenCover(isPresented: $showMeaningToHanziPractice) {
            MeaningToHanziPracticeScreen(topic: practiceTopic, subject: subject)
        }
    }

    private func loadCards(limit: Int? = nil) async {
        let effectiveLimit = limit ?? selectedLimit
        let cards: [Flashcard]
        if let topic = topic {
            let all = topic.flashcards.shuffled()
            cards = effectiveLimit > 0 ? Array(all.prefix(effectiveLimit)) : all
            await MainActor.run {
                totalCardCount = topic.flashcards.count
            }
        } else {
            let sid = subject.id
            let count = DatabaseManager.shared.countAllFlashcards(subjectId: sid)
            cards = await Task.detached {
                DatabaseManager.shared.loadAllFlashcards(subjectId: sid, limit: effectiveLimit > 0 ? effectiveLimit : nil)
            }.value
            await MainActor.run {
                totalCardCount = count
            }
        }
        await MainActor.run {
            loadedCards = cards
            isLoading = false
        }
    }

    private var headerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white)
            Text(topic != nil ? topic!.name : "Luyện tập toàn bộ \(subject.name)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text("\(totalCardCount) từ trong kho từ vựng")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primary.opacity(0.9), Color(red: 0.56, green: 0.34, blue: 0.89)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: AppTheme.primary.opacity(0.2), radius: 12, x: 0, y: 6)
    }

    private var limitPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Số lượng từ")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(limitOptions, id: \.self) { limit in
                        let isSelected = selectedLimit == limit
                        Button {
                            HapticFeedback.impact()
                            selectedLimit = limit
                        } label: {
                            Text(limit == 0 ? "Tất cả" : "\(limit) từ")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(isSelected ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isSelected ? AppTheme.primary : AppTheme.cardBg)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(isSelected ? Color.clear : AppTheme.textSecondary.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            let practiceCount = selectedLimit == 0 ? totalCardCount : min(selectedLimit, totalCardCount)
            Text("Sẽ trộn ngẫu nhiên \(practiceCount) từ để luyện tập")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}

struct PracticeTypeCard: View {
    let type: PracticeType
    let onTap: () -> Void

    private var icon: String {
        switch type {
        case .flipCard: return "rectangle.portrait.on.rectangle.portrait.fill"
        case .multipleChoice: return "list.bullet.rectangle.fill"
        case .listening: return "ear.fill"
        case .meaningToHanzi: return "character.book.closed.fill"
        }
    }

    private var description: String {
        switch type {
        case .flipCard: return "Lật thẻ để nhớ từ"
        case .multipleChoice: return "Chọn đáp án đúng"
        case .listening: return "Nghe và nhận diện từ"
        case .meaningToHanzi: return "Viết hán tự từ nghĩa"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(AppTheme.iconTint)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.iconTint.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
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
