import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 0) {
            Image(page.imageName)
                .resizable()
                .scaledToFit()
//                .frame(width: page.imageWidth, height: page.imageHeight)
                .padding(.horizontal, 16)
//                .padding(.top, 60)  

            Spacer().frame(height: 24)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(AppColors.navy)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.navy.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

#Preview {
    OnboardingPageView(page: OnboardingPage.pages[0])
}
