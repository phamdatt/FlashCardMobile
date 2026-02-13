//
//  SubjectsScreen.swift
//  FlashCardMobile
//

import SwiftUI

struct SubjectsScreen: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedSubject: Subject?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    streakBanner
                    subjectGrid
                }
                .padding()
            }
            .background(AppTheme.surface)
            .navigationTitle("Học tập")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.selectedTabIndex = 2
                    } label: {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .onAppear { viewModel.loadData() }
            .refreshable { viewModel.loadData() }
            .navigationDestination(item: $selectedSubject) { subject in
                TopicsScreen(subject: subject, viewModel: viewModel)
            }
        }
    }

    private var streakBanner: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: viewModel.streakInfo.didPracticeToday ? "flame.fill" : "flame")
                    .font(.title2)
                    .foregroundStyle(viewModel.streakInfo.didPracticeToday ? AppTheme.accentOrange : AppTheme.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.streakInfo.currentStreak) ngày")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Streak hiện tại")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .subtleCard()

            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.accentOrange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.streakInfo.longestStreak) ngày")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Kỷ lục")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .subtleCard()
        }
    }

    private var subjectGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(viewModel.subjects) { subject in
                SubjectCard(subject: subject) {
                    selectedSubject = subject
                }
            }
        }
    }
}

struct SubjectCard: View {
    let subject: Subject
    let onTap: () -> Void

    private var totalCards: Int {
        subject.topics.reduce(0) { $0 + $1.flashcards.count }
    }

    var body: some View {
        Button {
            HapticFeedback.impact()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: subject.displayIcon)
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text("\(totalCards)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.surface)
                        .clipShape(Capsule())
                }
                Text(subject.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(subject.topics.count) chủ đề")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(HapticButtonStyle())
    }
}
