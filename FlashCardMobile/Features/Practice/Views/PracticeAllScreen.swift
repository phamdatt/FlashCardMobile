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
    @State private var showMultipleChoicePractice = false
    @State private var showListeningPractice = false
    @State private var showMeaningToHanziPractice = false
    @State private var selectedLimit: Int = 0
    @State private var loadedCards: [Flashcard] = []
    @State private var totalCardCount: Int = 0
    @State private var isLoadingPractice = false

    private var limitOptions: [Int] {
        guard totalCardCount > 0 else { return [0] }
        let half = totalCardCount / 2
        let start = max(5, (half / 5) * 5)
        var options: [Int] = []
        var current = start
        while current <= totalCardCount {
            options.append(current)
            current += 5
        }
        if options.last != totalCardCount {
            options.append(0)
        }
        return options
    }

    private var practiceTopic: Topic {
        if let topic = topic {
            return Topic(id: topic.id, name: topic.name, subjectId: subject.id, flashcards: loadedCards)
        }
        return Topic(id: -1, name: "Tất cả \(subject.name)", subjectId: subject.id, flashcards: loadedCards)
    }

    private var availableTypes: [PracticeType] {
        PracticeType.availableTypes(subjectName: subject.name)
    }

    var body: some View {
        ZStack {
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
                            Task { await startPractice(type: type) }
                        }
                        .disabled(isLoadingPractice)
                    }
                }
                .padding()
            }

            if isLoadingPractice {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Đang tải từ vựng...")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .background(AppTheme.surface)
        .navigationTitle(topic != nil ? "Luyện tập" : "Luyện tập tất cả")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let topic = topic {
                totalCardCount = topic.flashcards.count
            } else {
                totalCardCount = DatabaseManager.shared.countAllFlashcards(subjectId: subject.id)
            }
            selectedLimit = limitOptions.first ?? 0
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

    private func startPractice(type: PracticeType) async {
        isLoadingPractice = true
        let cards: [Flashcard]
        let lim = selectedLimit
        if let topic = topic {
            let all = topic.flashcards.shuffled()
            cards = lim > 0 ? Array(all.prefix(lim)) : all
        } else {
            let sid = subject.id
            cards = await Task.detached {
                DatabaseManager.shared.loadAllFlashcards(subjectId: sid, limit: lim > 0 ? lim : nil)
            }.value
        }
        await MainActor.run {
            loadedCards = cards
            isLoadingPractice = false
            switch type {
            case .flipCard: break
            case .multipleChoice: showMultipleChoicePractice = true
            case .listening: showListeningPractice = true
            case .meaningToHanzi: showMeaningToHanziPractice = true
            }
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
                .fill(AppTheme.heroGradient)
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
                    Text(type.displayName )
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(type.descriptionText)
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
