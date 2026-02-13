//
//  StatisticsScreen.swift
//  FlashCardMobile
//

import SwiftUI

struct StatisticsScreen: View {
    @ObservedObject var viewModel: StatisticsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    streakSection
                    overviewSection
                    subjectBreakdown
                }
                .padding()
            }
            .background(AppTheme.surface)
            .navigationTitle("Thống kê")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { viewModel.loadData() }
            .refreshable { viewModel.loadData() }
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
                label: "Kỷ lục",
                color: AppTheme.accentOrange
            )
        }
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tổng quan")
                .font(.headline)
                .fontWeight(.semibold)
            HStack(spacing: 16) {
                StatCard(
                    icon: "rectangle.stack.fill",
                    value: "\(viewModel.totalCards)",
                    label: "Tổng từ",
                    color: AppTheme.primary
                )
                StatCard(
                    icon: "clock.fill",
                    value: "\(viewModel.dueCount)",
                    label: "Cần ôn",
                    color: AppTheme.accentOrange
                )
            }
        }
    }

    private var subjectBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Theo môn học")
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
                Text("\(cardCount) từ • \(subject.topics.count) chủ đề")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .cardStyle()
    }
}
