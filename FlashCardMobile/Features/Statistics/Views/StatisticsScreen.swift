//
//  StatisticsScreen.swift
//  FlashCardMobile
//

import SwiftUI
import Charts

struct StatisticsScreen: View {
    @ObservedObject var viewModel: StatisticsViewModel
    @State private var showMasteredList = false
    @State private var showWrongList = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    streakSection
                    progressChart
                    overviewSection
                    subjectBreakdown
                }
                .padding()
            }
            .background(AppTheme.surface)
            .navigationTitle(L("stats.title"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear { viewModel.loadData() }
            .refreshable { viewModel.loadData() }
            .sheet(isPresented: $showMasteredList) {
                MasteredWordsSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showWrongList) {
                FrequentlyWrongSheet(viewModel: viewModel)
            }
        }
    }

    private var streakSection: some View {
        HStack(spacing: 16) {
            StatCard(
                icon: "flame.fill",
                value: "\(viewModel.streakInfo.currentStreak)",
                label: "Streak",
                color: AppTheme.accentOrange
            )
            StatCard(
                icon: "trophy.fill",
                value: "\(viewModel.streakInfo.longestStreak)",
                label: L("stats.record"),
                color: AppTheme.accentOrange
            )
        }
    }

    // MARK: - Progress Chart

    private var progressChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("stats.progress"))
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 16) {
                // Donut chart
                Chart {
                    if viewModel.masteredCount > 0 {
                        SectorMark(
                            angle: .value(L("stats.mastered"), viewModel.masteredCount),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(AppTheme.accentGreen)
                        .annotation(position: .overlay) {
                            if viewModel.masteredCount > 5 {
                                Text("\(viewModel.masteredCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    if viewModel.learningCount > 0 {
                        SectorMark(
                            angle: .value(L("stats.learning"), viewModel.learningCount),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(AppTheme.accentOrange)
                        .annotation(position: .overlay) {
                            if viewModel.learningCount > 5 {
                                Text("\(viewModel.learningCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    if viewModel.newCount > 0 {
                        SectorMark(
                            angle: .value(L("stats.new"), viewModel.newCount),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.3))
                    }
                }
                .frame(height: 180)
                .chartBackground { _ in
                    VStack(spacing: 2) {
                        Text("\(viewModel.masteredCount)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text(L("stats.mastered_label"))
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                // Legend + tap actions
                VStack(spacing: 10) {
                    Button {
                        viewModel.loadMasteredCards()
                        showMasteredList = true
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(AppTheme.accentGreen)
                                .frame(width: 10, height: 10)
                            Text(L("stats.mastered"))
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(viewModel.masteredCount) \(L("common.words"))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(AppTheme.textSecondary)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Divider()

                    HStack(spacing: 12) {
                        Circle()
                            .fill(AppTheme.accentOrange)
                            .frame(width: 10, height: 10)
                        Text(L("stats.learning"))
                            .font(.subheadline)
                        Spacer()
                        Text("\(viewModel.learningCount) \(L("common.words"))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Divider()

                    Button {
                        viewModel.loadFrequentlyWrongCards()
                        showWrongList = true
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(AppTheme.accentRed)
                                .frame(width: 10, height: 10)
                            Text(L("stats.frequently_wrong"))
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(viewModel.frequentlyWrongCards.count > 0 ? "\(viewModel.frequentlyWrongCards.count)" : L("common.view")) \(L("common.words"))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(AppTheme.textSecondary)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Divider()

                    HStack(spacing: 12) {
                        Circle()
                            .fill(AppTheme.textSecondary.opacity(0.3))
                            .frame(width: 10, height: 10)
                        Text(L("stats.new"))
                            .font(.subheadline)
                        Spacer()
                        Text("\(viewModel.newCount) \(L("common.words"))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(20)
            .cardStyle()
        }
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("stats.overview"))
                .font(.headline)
                .fontWeight(.semibold)
            HStack(spacing: 16) {
                StatCard(
                    icon: "rectangle.stack.fill",
                    value: "\(viewModel.totalCards)",
                    label: L("stats.total_words"),
                    color: AppTheme.primary
                )
                StatCard(
                    icon: "clock.fill",
                    value: "\(viewModel.dueCount)",
                    label: L("stats.due_review"),
                    color: AppTheme.accentOrange
                )
            }
        }
    }

    private var subjectBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("stats.by_subject"))
                .font(.headline)
                .fontWeight(.semibold)
            VStack(spacing: 12) {
                ForEach(viewModel.subjects) { subject in
                    SubjectStatRow(subject: subject)
                }
            }
        }
    }
}

// MARK: - Mastered Words Sheet

struct MasteredWordsSheet: View {
    @ObservedObject var viewModel: StatisticsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.masteredCards.isEmpty {
                    ContentUnavailableView(
                        L("stats.no_mastered"),
                        systemImage: "star",
                        description: Text(L("stats.no_mastered_desc"))
                    )
                } else {
                    List(viewModel.masteredCards) { card in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.questionDisplayTextWithPhonetic)
                                    .font(.headline)
                                Text(card.answer)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(AppTheme.accentGreen)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.surface)
                }
            }
            .navigationTitle(L("stats.mastered_title", viewModel.masteredCards.count))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("common.close")) { dismiss() }
                }
            }
        }
    }
}

// MARK: - Frequently Wrong Sheet

struct FrequentlyWrongSheet: View {
    @ObservedObject var viewModel: StatisticsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.frequentlyWrongCards.isEmpty {
                    ContentUnavailableView(
                        L("stats.no_wrong"),
                        systemImage: "checkmark.seal",
                        description: Text(L("stats.no_wrong_desc"))
                    )
                } else {
                    List(viewModel.frequentlyWrongCards, id: \.flashcard.id) { item in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.flashcard.questionDisplayTextWithPhonetic)
                                    .font(.headline)
                                Text(item.flashcard.answer)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            Text(L("stats.wrong_count", item.count))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(AppTheme.accentRed)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.accentRed.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.surface)
                }
            }
            .navigationTitle("Từ hay sai")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("common.close")) { dismiss() }
                }
            }
        }
        .onAppear { viewModel.loadFrequentlyWrongCards() }
    }
}

// MARK: - Reusable Components

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .cardStyle()
    }
}

struct SubjectStatRow: View {
    let subject: Subject

    private var cardCount: Int {
        subject.topics.reduce(0) { $0 + $1.flashcards.count }
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: subject.displayIcon)
                .font(.title2)
                .foregroundStyle(AppTheme.iconTint)
                .frame(width: 40, alignment: .center)
            VStack(alignment: .leading, spacing: 4) {
                Text(subject.name)
                    .font(.headline)
                Text("\(cardCount) từ \u{2022} \(subject.topics.count) chủ đề")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .cardStyle()
    }
}
