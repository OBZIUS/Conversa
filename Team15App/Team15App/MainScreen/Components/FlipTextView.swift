import SwiftUI

struct FlipTextView: View {
    let text: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            FittingText(
                text: text.isEmpty ? "Type your message first" : text,
                minFontSize: 28,
                maxFontSize: 120,
                fontWeight: .semibold,
                uiFontWeight: .semibold
            )
            .rotationEffect(.degrees(180))
            .onTapGesture(perform: onDismiss)

            VStack {
                Spacer()
                HStack {
//                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColors.navy)
                            .frame(width: 44, height: 44)
                            .background(AppColors.cardBg, in: Circle())
                    }
                }
//                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
}

#Preview {
    FlipTextView(
        text: "Hi there, my name is Leo and I am deaf. I use this app to communicate with you.",
        onDismiss: {}
    )
}
