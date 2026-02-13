//
//  FlipCardPracticeScreen.swift
//  FlashCardMobile
//

import SwiftUI

struct FlipCardPracticeScreen: View {
    let topic: Topic
    let subject: Subject
    @Environment(\.dismiss) private var dismiss
    @State private var cards: [Flashcard] = []
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var score = 0
    @State private var totalAnswered = 0
    @State private var showResult = false
    @State private var dragOffset: CGFloat = 0
    @AppStorage("practice_show_pinyin") private var showPinyin = true

    var body: some View {
        ZStack {
            AppTheme.surface
                .ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                Spacer()
                if cards.isEmpty {
                    emptyState
                } else {
                    cardView
                }
                Spacer()
                if !cards.isEmpty {
                    bottomControls
                }
            }
        }
        .onAppear {
            cards = topic.flashcards.shuffled()
        }
        .sheet(isPresented: $showResult) {
            PracticeResultSheet(
                score: score,
                total: totalAnswered,
                onDismiss: {
                    showResult = false
                    dismiss()
                }
            )
        }
    }

    private var progressBar: some View {
        VStack(spacing: 12) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Text("\(currentIndex + 1) / \(cards.count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }
            pinyinToggle
        }
        .padding()
    }

    private var pinyinToggle: some View {
        HStack {
            Label("Pinyin", systemImage: "textformat.phonetic")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Toggle("", isOn: $showPinyin)
                .labelsHidden()
                .tint(AppTheme.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Không có thẻ",
            systemImage: "rectangle.stack",
            description: Text("Chủ đề này chưa có từ vựng để luyện tập.")
        )
    }

    private var cardView: some View {
        let card = cards[currentIndex]
        return ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primary.opacity(0.9), Color(red: 0.56, green: 0.34, blue: 0.89)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: AppTheme.primary.opacity(0.15), radius: 12, x: 0, y: 4)
                .frame(height: 280)
                .padding(.horizontal, 24)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )

            VStack(spacing: 16) {
                if isFlipped {
                    Text(card.answer)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    Text(card.questionDisplayText)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    if showPinyin, let phonetic = card.displayPhonetic, !phonetic.isEmpty {
                        Text(phonetic)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
            }
        }
        .onTapGesture {
            HapticFeedback.impact()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isFlipped.toggle()
            }
        }
    }

    private var bottomControls: some View {
        HStack(spacing: 24) {
            Button {
                HapticFeedback.impact()
                recordAnswer(correct: false)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.accentRed)
            }
            .buttonStyle(HapticButtonStyle())

            Button {
                HapticFeedback.impact()
                recordAnswer(correct: true)
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.accentGreen)
            }
            .buttonStyle(HapticButtonStyle())
        }
        .padding(.vertical, 32)
    }

    private func recordAnswer(correct: Bool) {
        totalAnswered += 1
        if correct { score += 1 }

        let card = cards[currentIndex]
        DatabaseManager.shared.ensureProgressExists(flashcardId: card.id)
        if var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: card.id) {
            progress.totalReviews += 1
            if correct { progress.correctReviews += 1 }
            else {
                progress.incorrectReviews += 1
                DatabaseManager.shared.recordMistake(flashcardId: card.id, practiceType: "Thẻ lật", topicId: topic.id)
            }
            DatabaseManager.shared.saveFlashcardProgress(progress)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        DatabaseManager.shared.recordPracticeSession(
            practiceDate: formatter.string(from: Date()),
            practiceType: "Thẻ lật",
            topicId: topic.id,
            correct: correct ? 1 : 0,
            total: 1
        )

        if currentIndex + 1 >= cards.count {
            showResult = true
        } else {
            withAnimation {
                currentIndex += 1
                isFlipped = false
            }
        }
    }
}

struct PracticeResultSheet: View {
    let score: Int
    let total: Int
    let onDismiss: () -> Void

    private var percentage: Int {
        guard total > 0 else { return 0 }
        return Int((Double(score) / Double(total)) * 100)
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.accentGreen)
            Text("Hoàn thành!")
                .font(.title)
                .fontWeight(.bold)
            Text("\(score)/\(total) đúng (\(percentage)%)")
                .font(.title2)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Button {
                HapticFeedback.impact()
                onDismiss()
            } label: {
                Text("Đóng")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primaryGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding()
        }
        .background(AppTheme.surface)
    }
}
