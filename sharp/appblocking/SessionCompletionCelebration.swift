//
//  SessionCompletionCelebration.swift
//  sharp
//
//  Celebration animation for session completion with confetti
//

import SwiftUI

struct SessionCompletionCelebration: View {
    let sessionType: BlockingType
    @Binding var show: Bool

    @State private var confettiOffset: CGFloat = -50
    @State private var checkmarkScale: CGFloat = 0
    @State private var textScale: CGFloat = 0

    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { show = false }

            VStack(spacing: 24) {
                // Confetti burst
                ZStack {
                    ForEach(0..<30) { i in
                        Circle()
                            .fill(randomColor())
                            .frame(width: 10, height: 10)
                            .offset(
                                x: cos(Double(i) * 12) * confettiOffset * 3,
                                y: sin(Double(i) * 12) * confettiOffset * 3
                            )
                            .opacity(confettiOffset > 0 ? 0 : 1)
                    }
                }

                // Checkmark with 3D solid shadow
                ZStack {
                    // Solid shadow
                    Circle()
                        .fill(Color.uwSuccess.darker(by: 0.3))
                        .frame(width: 100, height: 100)
                        .offset(y: 6)

                    Circle()
                        .fill(Color.uwSuccess)
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .heavy))
                        .foregroundColor(.white)
                }
                .scaleEffect(checkmarkScale)

                // Text
                VStack(spacing: 8) {
                    Text("Session Complete!")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(.white)

                    Text("Great focus! Apps are now unlocked.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .scaleEffect(textScale)

                // Continue button
                Button {
                    show = false
                } label: {
                    Text("Continue")
                        .font(.system(size: 18, weight: .heavy))
                }
                .buttonStyle(DuolingoButton(color: .accentGreen))
            }
            .padding(40)
        }
        .onAppear {
            // Confetti burst
            withAnimation(.easeOut(duration: 1.0)) {
                confettiOffset = 150
            }

            // Checkmark bounce
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3)) {
                checkmarkScale = 1.0
            }

            // Text pop
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.5)) {
                textScale = 1.0
            }

            // Haptics sequence
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }

    private func randomColor() -> Color {
        [.accentGreen, .accentYellow, .accentPurple, .brandPrimary, .accentOrange].randomElement()!
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var show = true

    SessionCompletionCelebration(
        sessionType: .timer,
        show: $show
    )
}
