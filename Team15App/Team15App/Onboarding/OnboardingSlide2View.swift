import SwiftUI

struct OnboardingSlide2View: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Illustration
            Image("onb2")
                .resizable()
                .scaledToFit()
                .frame(width: 266, height: 364)
                .padding(.horizontal, 16)
                .padding(.top, 60)

            Spacer().frame(height: 24)

            // MARK: - Text Content
            VStack(spacing: 12) {
                Text("Express yourself\nwith ease")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(AppColors.navy)
                    .multilineTextAlignment(.center)

                Text("Respond faster with smart suggestions\ntailored to your travel needs")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.navy.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()

            // MARK: - Page Dots
            HStack(spacing: 8) {
                Circle()
                    .fill(AppColors.navy.opacity(0.2))
                    .frame(width: 8, height: 8)
                Circle()
                    .fill(AppColors.navy)
                    .frame(width: 8, height: 8)
                Circle()
                    .fill(AppColors.navy.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
            .padding(.bottom, 44)

            // MARK: - Next Button
            Button("Next", action: onNext)
                .buttonStyle(PrimaryButtonStyle(foregroundColor: AppColors.navy))
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
        .background(Color.white)
    }
}

#Preview {
    OnboardingSlide2View(onNext: {})
}
