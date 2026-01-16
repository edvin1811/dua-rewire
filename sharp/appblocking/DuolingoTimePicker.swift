//
//  DuolingoTimePicker.swift
//  sharp
//
//  Custom wheel-style time picker with Duolingo animations
//

import SwiftUI

struct DuolingoTimePicker: View {
    @Binding var selectedMinutes: Int
    let options: [Int] // e.g., [1, 15, 30, 45, 60, 90, 120, 180, 240]

    @State private var scrollOffset: CGFloat = 0
    @State private var selectedIndex: Int = 0

    private let itemHeight: CGFloat = 60

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Center highlight bar
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brandPrimary.opacity(0.15))
                    .frame(height: itemHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.brandPrimary, lineWidth: 2)
                    )
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                // Scrolling options
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(options.indices, id: \.self) { index in
                                timeOption(
                                    minutes: options[index],
                                    isSelected: options[index] == selectedMinutes,
                                    index: index
                                )
                                .frame(height: itemHeight)
                                .id(index)
                                .onTapGesture {
                                    selectOption(at: index, proxy: proxy)
                                }
                            }
                        }
                        .padding(.vertical, geometry.size.height / 2 - itemHeight / 2)
                    }
                    .onAppear {
                        // Scroll to initially selected value
                        if let initialIndex = options.firstIndex(of: selectedMinutes) {
                            selectedIndex = initialIndex
                            proxy.scrollTo(initialIndex, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(height: 240)
    }

    private func timeOption(minutes: Int, isSelected: Bool, index: Int) -> some View {
        ZStack {
            HStack(spacing: 8) {
                Text("\(minutes)")
                    .font(.system(size: isSelected ? 48 : 32, weight: .heavy))
                    .foregroundColor(isSelected ? .brandPrimary : .textSecondary)
                    .monospacedDigit()

                Text("min")
                    .font(.system(size: isSelected ? 16 : 14, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .offset(y: isSelected ? 8 : 5)
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }

    private func selectOption(at index: Int, proxy: ScrollViewProxy) {
        selectedIndex = index
        selectedMinutes = options[index]

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            proxy.scrollTo(index, anchor: .center)
        }

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var selectedMinutes = 30

    VStack(spacing: 20) {
        Text("Select Duration")
            .font(.system(size: 24, weight: .bold))

        DuolingoTimePicker(
            selectedMinutes: $selectedMinutes,
            options: [1, 15, 30, 45, 60, 90, 120, 180, 240]
        )

        Text("Selected: \(selectedMinutes) minutes")
            .font(.system(size: 16, weight: .medium))
    }
    .padding()
    .background(Color.appBackground)
}
