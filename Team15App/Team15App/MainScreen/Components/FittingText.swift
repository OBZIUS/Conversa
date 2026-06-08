import SwiftUI

struct FittingText: View {
    let text: String
    var minFontSize: CGFloat = 24
    var maxFontSize: CGFloat = 120
    var fontWeight: Font.Weight = .semibold
    var uiFontWeight: UIFont.Weight = .semibold
    var horizontalPadding: CGFloat = 32
    var verticalPadding: CGFloat = 32
    var alignment: TextAlignment = .center
    var textColor: Color = AppColors.navy

    @State private var fontSize: CGFloat = 24
    @State private var containerSize: CGSize = .zero

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundStyle(textColor)
            .multilineTextAlignment(alignment)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: frameAlignment)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .animation(.easeInOut(duration: 0.15), value: fontSize)
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            containerSize = geometry.size
                            recalculateFontSize()
                        }
                        .onChange(of: geometry.size) { _, newSize in
                            containerSize = newSize
                            recalculateFontSize()
                        }
                }
            }
            .onChange(of: text) { _, _ in recalculateFontSize() }
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .leading: .leading
        case .trailing: .trailing
        default: .center
        }
    }

    private var textAreaSize: CGSize {
        CGSize(
            width: max(containerSize.width - horizontalPadding * 2, 0),
            height: max(containerSize.height - verticalPadding * 2, 0)
        )
    }

    private func recalculateFontSize() {
        let target = FittingFontSizeCalculator.fittingSize(
            text: text,
            in: textAreaSize,
            min: minFontSize,
            max: maxFontSize,
            weight: uiFontWeight
        )
        if fontSize != target {
            fontSize = target
        }
    }
}
