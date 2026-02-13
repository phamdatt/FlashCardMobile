//
//  OnboardingScreen.swift
//  FlashCardMobile
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

struct OnboardingScreen: View {
    let onFinish: () -> Void
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "book.fill",
            title: "Học từ vựng theo chủ đề",
            description: "Chọn môn học và chủ đề để bắt đầu học từ vựng. Hỗ trợ Tiếng Anh, Tiếng Trung và Bài đọc."
        ),
        OnboardingPage(
            icon: "play.circle.fill",
            title: "Nhiều kiểu luyện tập",
            description: "Thẻ lật, trắc nghiệm, nghe chọn đáp án. Tiếng Trung còn có luyện Nghĩa → Hán tự."
        ),
        OnboardingPage(
            icon: "arrow.clockwise.circle.fill",
            title: "Ôn tập theo lịch SRS",
            description: "Hệ thống tự nhắc bạn ôn lại từ vựng đúng thời điểm để ghi nhớ lâu hơn."
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            title: "Theo dõi tiến độ",
            description: "Xem streak, thống kê học tập và theo dõi sự tiến bộ của bạn."
        )
    ]

    var body: some View {
        ZStack {
            AppTheme.surface
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        onboardingPageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                pageIndicator
                bottomButtons
            }
        }
    }

    private func onboardingPageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.15))
                    .frame(width: 140, height: 140)
                Image(systemName: page.icon)
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.primary)
            }
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? AppTheme.primary : AppTheme.textSecondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.bottom, 24)
    }

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            Button {
                HapticFeedback.impact()
                if currentPage == pages.count - 1 {
                    onFinish()
                } else {
                    withAnimation { currentPage += 1 }
                }
            } label: {
                Text(currentPage == pages.count - 1 ? "Bắt đầu" : "Tiếp theo")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.primaryGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            if currentPage < pages.count - 1 {
                Button {
                    HapticFeedback.impact()
                    onFinish()
                } label: {
                    Text("Bỏ qua")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}
