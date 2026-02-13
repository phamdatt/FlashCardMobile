//
//  SplashScreen.swift
//  FlashCardMobile
//

import SwiftUI

struct SplashScreen: View {
    let onFinish: () -> Void
    @State private var bookOpen: CGFloat = 0
    @State private var birdOffset: CGSize = .zero
    @State private var birdOpacity: Double = 1
    @State private var birdScale: CGFloat = 0.5
    @State private var birdRotation: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            AppTheme.primaryGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    AnimatedBook(openAmount: bookOpen)
                        .frame(width: 150, height: 100)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5)

                    SwallowShape()
                        .fill(.white)
                        .frame(width: 48, height: 32)
                        .scaleEffect(birdScale)
                        .rotationEffect(.degrees(birdRotation))
                        .offset(x: 40 + birdOffset.width, y: -38 + birdOffset.height)
                        .opacity(birdOpacity)
                        .shadow(color: .black.opacity(0.25), radius: 4)
                }
                .frame(height: 200)

                Spacer()
                VStack(spacing: 8) {
                    Text("FlashCard")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Học từ vựng hiệu quả")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .opacity(textOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                bookOpen = 1
            }
            withAnimation(.easeOut(duration: 0.6)) {
                birdScale = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeOut(duration: 0.5)) {
                    textOpacity = 1
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    birdOffset = CGSize(width: 120, height: -180)
                    birdOpacity = 0
                    birdRotation = -15
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.9) {
                onFinish()
            }
        }
    }
}

struct AnimatedBook: View {
    let openAmount: CGFloat

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let coverW = w * 0.48
            let coverH = h * 0.88
            let spineW: CGFloat = 4
            let angle = Double(openAmount) * 85

            ZStack {
                // Spine — gáy sách ở giữa
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white.opacity(0.9))
                    .frame(width: spineW, height: coverH)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)

                // Bìa trái — xoay quanh mép phải (gáy)
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white)
                    .frame(width: coverW, height: coverH)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.white.opacity(0.6), lineWidth: 1)
                            .blur(radius: 0.5)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: -2, y: 2)
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.08)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 12)
                            .mask(RoundedRectangle(cornerRadius: 6))
                    }
                    .rotation3DEffect(.degrees(-angle), axis: (x: 0, y: 1, z: 0), anchor: .trailing, perspective: 0.4)
                    .offset(x: -spineW / 2)

                // Bìa phải — xoay quanh mép trái (gáy)
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white)
                    .frame(width: coverW, height: coverH)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.white.opacity(0.6), lineWidth: 1)
                            .blur(radius: 0.5)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.black.opacity(0.08), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 12)
                            .mask(RoundedRectangle(cornerRadius: 6))
                    }
                    .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.4)
                    .offset(x: spineW / 2)
            }
            .frame(width: w, height: h)
        }
    }
}

/// Chim én — silhouette với đuôi chẻ đặc trưng (forked tail), cánh dang rộng khi bay
struct SwallowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = h * 0.5

        // Silhouette liền mạch: đầu → thân → đuôi chẻ + cánh
        // Đầu nhỏ phía trước
        path.move(to: CGPoint(x: w * 0.08, y: cx))
        path.addQuadCurve(to: CGPoint(x: w * 0.2, y: cx - h * 0.08), control: CGPoint(x: w * 0.1, y: cx - h * 0.12))
        path.addQuadCurve(to: CGPoint(x: w * 0.35, y: cx), control: CGPoint(x: w * 0.28, y: cx - h * 0.12))

        // Thân + cánh trái (phía trên)
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: cx - h * 0.45), control: CGPoint(x: w * 0.38, y: cx - h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.72, y: cx - h * 0.15))
        path.addQuadCurve(to: CGPoint(x: w * 0.78, y: cx), control: CGPoint(x: w * 0.76, y: cx - h * 0.08))

        // Đuôi chẻ — nhánh trên
        path.addLine(to: CGPoint(x: w * 0.98, y: cx - h * 0.38))
        path.addLine(to: CGPoint(x: w * 0.85, y: cx))
        path.addLine(to: CGPoint(x: w * 0.78, y: cx))

        // Đuôi chẻ — nhánh dưới
        path.addLine(to: CGPoint(x: w * 0.98, y: cx + h * 0.38))
        path.addLine(to: CGPoint(x: w * 0.72, y: cx + h * 0.15))

        // Cánh phải (phía dưới)
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: cx + h * 0.45), control: CGPoint(x: w * 0.38, y: cx + h * 0.5))
        path.addQuadCurve(to: CGPoint(x: w * 0.08, y: cx), control: CGPoint(x: w * 0.28, y: cx + h * 0.12))

        path.closeSubpath()
        return path
    }
}
