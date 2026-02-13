//
//  ReviewScreen.swift
//  FlashCardMobile
//

import SwiftUI

struct ReviewScreen: View {
    @ObservedObject var viewModel: ReviewViewModel
    @ObservedObject var appViewModel: AppViewModel
    @AppStorage("practice_show_pinyin") private var showPinyin = true

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.surface
                    .ignoresSafeArea()

                if viewModel.isEmpty {
                    emptyState
                } else if viewModel.showComplete {
                    completeView
                } else {
                    reviewContent
                }
            }
            .navigationTitle("Ôn tập SRS")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appViewModel.selectedTabIndex = 2
                    } label: {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .onAppear {
                viewModel.loadDue()
                viewModel.refreshStreak()
            }
        }
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
            "Không có thẻ cần ôn",
            systemImage: "checkmark.circle",
            description: Text("Hãy luyện tập để có thẻ ôn lại theo lịch.")
        )
    }

    private var completeView: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.accentOrange)
            Text("Hoàn thành!")
                .font(.title)
                .fontWeight(.bold)
            Text("Bạn đã ôn hết thẻ hôm nay")
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var reviewContent: some View {
        VStack(spacing: 0) {
            Text("\(viewModel.currentIndex + 1) / \(viewModel.cards.count)")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

            pinyinToggle
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            if let card = viewModel.currentCard {
                VStack(spacing: 24) {
                    ZStack {
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

                        VStack(spacing: 12) {
                            if viewModel.showAnswer {
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
                        if viewModel.showAnswer {
                            if let c = viewModel.currentCard {
                                viewModel.submitQuality(card: c, quality: 1.0)
                            }
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.revealAnswer()
                            }
                        }
                    }

                    if viewModel.showAnswer {
                        Text("Chạm để tiếp")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            Spacer()
        }
    }

}
