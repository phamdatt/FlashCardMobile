import SwiftUI

struct SplashScreen: View {
    let onFinish: () -> Void

    // States for animations
    @State private var cardsAppeared = false
    @State private var cardsFanned = false
    @State private var frontFlipped = false
    @State private var textAnimated = false
    @State private var bgAnimate = false
    @State private var sparkles: [ModernSparkle] = []

    var body: some View {
        ZStack {
            // 1. Modern Background: Animated Mesh-like Gradient
            LinearGradient(colors: [AppTheme.primary, AppTheme.accentViolet], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay(
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentOrange.opacity(0.4))
                            .frame(width: 400)
                            .offset(x: bgAnimate ? 100 : -100, y: bgAnimate ? -200 : -150)
                        Circle()
                            .fill(AppTheme.accentViolet.opacity(0.4))
                            .frame(width: 300)
                            .offset(x: bgAnimate ? -120 : 120, y: bgAnimate ? 200 : 150)
                    }
                    .blur(radius: 80)
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                        bgAnimate.toggle()
                    }
                }

            // 2. Sparkle Particles
            ForEach(sparkles) { s in
                Image(systemName: "sparkle")
                    .font(.system(size: s.size))
                    .foregroundStyle(.white)
                    .position(x: s.x, y: s.y)
                    .opacity(s.opacity)
                    .scaleEffect(s.opacity)
            }

            VStack(spacing: 0) {
                Spacer()

                // 3. Card Stack Area
                ZStack {
                    // Central Glow
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 250)
                        .blur(radius: 50)
                        .scaleEffect(frontFlipped ? 1.2 : 0.8)

                    // Card 2 (Back-right) - Chinese
                    ModernSplashCard(
                        character: "你好", subtitle: "nǐ hǎo",
                        color: AppTheme.accentViolet,
                        rotation: cardsFanned ? 15 : 0,
                        xOffset: cardsFanned ? 40 : 0,
                        scale: cardsAppeared ? 1 : 0.5
                    )

                    // Card 1 (Back-left) - English
                    ModernSplashCard(
                        character: "Hello", subtitle: "xin chào",
                        color: AppTheme.accentOrange,
                        rotation: cardsFanned ? -15 : 0,
                        xOffset: cardsFanned ? -40 : 0,
                        scale: cardsAppeared ? 1 : 0.5
                    )

                    // Card 0 (Front - Flipping)
                    ModernFlipCard(isFlipped: frontFlipped, appeared: cardsAppeared)
                }
                .frame(height: 300)

                Spacer()

                // 4. Branding Area
                VStack(spacing: 12) {
                    Text("FlashCard")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.1), radius: 10)
                        .blur(radius: textAnimated ? 0 : 10)
                    
                    Text(L("splash.subtitle").uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .opacity(textAnimated ? 1 : 0)
                .offset(y: textAnimated ? 0 : 20)
                .padding(.bottom, 50)
            }
        }
        .onAppear { startModernAnimation() }
    }

    private func startModernAnimation() {
        // Phase 1: Pop in with heavy bounce
        withAnimation(.spring(duration: 0.6, bounce: 0.5)) {
            cardsAppeared = true
        }

        // Phase 2: Fan out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(duration: 0.7, bounce: 0.4)) {
                cardsFanned = true
            }
        }

        // Phase 3: Flip and Haptic
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                frontFlipped = true
            }
            emitModernSparkles()
        }

        // Phase 4: Text reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeOut(duration: 0.8)) {
                textAnimated = true
            }
        }

        // Finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            onFinish()
        }
    }

    private func emitModernSparkles() {
        let center = CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2 - 50)
        for i in 0..<12 {
            let angle = Double(i) * (.pi * 2 / 12)
            let s = ModernSparkle(
                id: i,
                x: center.x,
                y: center.y,
                size: CGFloat.random(in: 10...20),
                opacity: 0
            )
            sparkles.append(s)
            
            withAnimation(.interpolatingSpring(stiffness: 50, damping: 5).delay(Double(i) * 0.02)) {
                sparkles[i].x += cos(angle) * 150
                sparkles[i].y += sin(angle) * 150
                sparkles[i].opacity = 0.8
            }
        }
    }
}

// MARK: - Components

struct ModernSplashCard: View {
    let character: String
    let subtitle: String
    let color: Color
    let rotation: Double
    let xOffset: CGFloat
    let scale: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            Text(character)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(width: 130, height: 175)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(color.gradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.3), radius: 15, x: 0, y: 10)
        .rotationEffect(.degrees(rotation))
        .offset(x: xOffset)
        .scaleEffect(scale)
    }
}

struct ModernFlipCard: View {
    let isFlipped: Bool
    let appeared: Bool

    var body: some View {
        ZStack {
            // Front face - "学 · A" (Chinese + English combined)
            VStack(spacing: 6) {
                Text("学")
                    .font(.system(size: 38, weight: .heavy))
                    .foregroundStyle(.white)
                Text("learn")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .frame(width: 130, height: 175)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppTheme.primary.gradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: AppTheme.primary.opacity(0.3), radius: 15, x: 0, y: 10)
            .scaleEffect(appeared ? 1.05 : 0.5)
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 0 : 1)

            // Back face - Clean checkmark only
            Image(systemName: "checkmark")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 130, height: 175)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AppTheme.accentGreen.gradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                )
                .shadow(color: AppTheme.accentGreen.opacity(0.4), radius: 20, x: 0, y: 10)
                .scaleEffect(appeared ? 1.05 : 0.5)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)
        }
    }
}

struct ModernSparkle: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
}

#Preview {
    SplashScreen(onFinish: {})
}