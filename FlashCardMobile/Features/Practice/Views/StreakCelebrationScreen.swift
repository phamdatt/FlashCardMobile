//
//  StreakCelebrationScreen.swift
//  FlashCardMobile
//

import SwiftUI

struct StreakCelebrationScreen: View {
    let streakInfo: StreakInfo
    let onDismiss: () -> Void

    @State private var flameScale: CGFloat = 0.3
    @State private var flameOpacity: Double = 0
    @State private var numberOffset: CGFloat = 30
    @State private var numberOpacity: Double = 0
    @State private var detailsOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var particlesVisible = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.11, blue: 0.22),
                    Color(red: 0.20, green: 0.15, blue: 0.35),
                    Color(red: 0.30, green: 0.18, blue: 0.42)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Floating particles
            if particlesVisible {
                FloatingParticles()
            }

            VStack(spacing: 0) {
                Spacer()

                // Flame icon
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(AppTheme.accentOrange.opacity(0.15))
                        .frame(width: 160, height: 160)
                        .blur(radius: 30)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 90))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.accentOrange, Color(red: 1.0, green: 0.35, blue: 0.20)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: AppTheme.accentOrange.opacity(0.6), radius: 20, x: 0, y: 8)
                }
                .scaleEffect(flameScale)
                .opacity(flameOpacity)

                Spacer().frame(height: 32)

                // Streak number
                VStack(spacing: 8) {
                    Text("\(streakInfo.currentStreak)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(streakInfo.currentStreak == 1 ? "ngày streak" : "ngày streak liên tiếp")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .offset(y: numberOffset)
                .opacity(numberOpacity)

                Spacer().frame(height: 40)

                // Stats cards
                HStack(spacing: 16) {
                    StreakStatCard(
                        icon: "trophy.fill",
                        value: "\(streakInfo.longestStreak)",
                        label: "Kỷ lục",
                        color: AppTheme.accentOrange
                    )
                    StreakStatCard(
                        icon: "calendar.badge.checkmark",
                        value: "Hôm nay",
                        label: "Đã hoàn thành",
                        color: AppTheme.accentGreen
                    )
                }
                .padding(.horizontal, 32)
                .opacity(detailsOpacity)

                Spacer().frame(height: 24)

                // Motivational message
                Text(motivationalMessage)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(detailsOpacity)

                Spacer()

                // Continue button
                Button {
                    HapticFeedback.impact()
                    onDismiss()
                } label: {
                    Text("Tiếp tục")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.accentOrange, Color(red: 1.0, green: 0.40, blue: 0.20)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppTheme.accentOrange.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(buttonOpacity)
            }
        }
        .onAppear {
            runAnimations()
        }
    }

    private var motivationalMessage: String {
        switch streakInfo.currentStreak {
        case 1: return "Khởi đầu tuyệt vời! Hãy tiếp tục học mỗi ngày nhé!"
        case 2...4: return "Tốt lắm! Bạn đang xây dựng thói quen tốt!"
        case 5...9: return "Xuất sắc! Sự kiên trì sẽ mang lại kết quả!"
        case 10...29: return "Đáng kinh ngạc! Bạn thật sự rất chăm chỉ!"
        case 30...99: return "Phi thường! Bạn là nguồn cảm hứng!"
        default: return "Huyền thoại! Không gì có thể ngăn cản bạn!"
        }
    }

    private func runAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
            flameScale = 1.0
            flameOpacity = 1.0
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4)) {
            numberOffset = 0
            numberOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            detailsOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.9)) {
            buttonOpacity = 1.0
        }
        withAnimation(.easeIn(duration: 0.3).delay(0.2)) {
            particlesVisible = true
        }
    }
}

// MARK: - Streak Stat Card

private struct StreakStatCard: View {
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
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Floating Particles

private struct FloatingParticles: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(particleColor(for: i))
                    .frame(width: particleSize(for: i), height: particleSize(for: i))
                    .offset(
                        x: animate ? particleX(for: i) : particleX(for: i) * 0.3,
                        y: animate ? particleY(for: i) : particleY(for: i) * 0.5 + 50
                    )
                    .opacity(animate ? 0 : 0.7)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) {
                animate = true
            }
        }
    }

    private func particleColor(for index: Int) -> Color {
        let colors: [Color] = [AppTheme.accentOrange, .yellow, .orange, AppTheme.accentViolet]
        return colors[index % colors.count]
    }

    private func particleSize(for index: Int) -> CGFloat {
        CGFloat([6, 8, 5, 7, 9, 6, 8, 5, 7, 6, 8, 5][index])
    }

    private func particleX(for index: Int) -> CGFloat {
        CGFloat([-80, 60, -40, 90, -70, 50, -100, 80, -30, 110, -60, 70][index])
    }

    private func particleY(for index: Int) -> CGFloat {
        CGFloat([-120, -160, -100, -140, -180, -130, -150, -110, -170, -90, -200, -145][index])
    }
}
