import SwiftUI

struct OnboardingView: View {
    let onSkip: () -> Void
    let onFinish: () -> Void

    @State private var currentPage: Int = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $currentPage) {
                OnboardingSlide1View(
                    onNext: {
                        withAnimation {
                            currentPage = 1
                        }
                    }
                )
                .tag(0)

                OnboardingSlide2View(
                    onNext: {
                        withAnimation {
                            currentPage = 2
                        }
                    }
                )
                .tag(1)

                OnboardingSlide3View(
                    onNext: {
                        onFinish()
                    }
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .gesture(DragGesture())
            .ignoresSafeArea()

            // Skip button — always visible, skips onboarding
            Button("Skip") {
                onSkip()
            }
            .font(.system(size: 19, weight: .bold))
            .foregroundColor(AppColors.navy)
            .padding(.top, 25)
            .padding(.trailing, 25)
        }
        .background(Color.white.ignoresSafeArea())
    }
}

#Preview {
    OnboardingView(onSkip: {}, onFinish: {})
}
