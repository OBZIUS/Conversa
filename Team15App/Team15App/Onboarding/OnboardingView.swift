import SwiftUI

struct OnboardingView: View {
    let onSkip: () -> Void
    let onFinish: () -> Void

    @State private var currentPage: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let totalPages = OnboardingPage.pages.count

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") {
                    onSkip()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppColors.navy)
            }
            .padding(.horizontal, 24)
            .padding(.top, 17)

            TabView(selection: $currentPage) {
                ForEach(OnboardingPage.pages) { page in
                    OnboardingPageView(page: page)
                        .tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: .infinity)
            .padding(.bottom, 32)

            pageIndicator
                .padding(.bottom, 16)

            primaryButton
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .background(Color.white)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? AppColors.navy : AppColors.navy.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var primaryButton: some View {
        Button(action: primaryAction) {
            Text("Next")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppColors.navy)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
        }
        .background(AppColors.orange, in: Capsule())
    }

    private func primaryAction() {
        if currentPage < totalPages - 1 {
            let nextPage = currentPage + 1
            if reduceMotion {
                currentPage = nextPage
            } else {
                withAnimation {
                    currentPage = nextPage
                }
            }
        } else {
            onFinish()
        }
    }
}

#Preview {
    OnboardingView(onSkip: {}, onFinish: {})
}
