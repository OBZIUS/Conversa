import SwiftUI

struct FittingTextEditor: View {
    @Binding var text: String
    var focus: FocusState<Bool>.Binding
    var availableSize: CGSize
    var minFontSize: CGFloat = 18
    var maxFontSize: CGFloat = 80
    var contentPadding: CGFloat = 12

    @State private var fontSize: CGFloat = 18

    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: fontSize, weight: .regular))
            .foregroundStyle(AppColors.navy)
            .scrollContentBackground(.hidden)
            .padding(contentPadding)
            .focused(focus)
            .animation(.easeInOut(duration: 0.15), value: fontSize)
            .onAppear { recalculateFontSize() }
            .onChange(of: text) { _, _ in recalculateFontSize() }
            .onChange(of: availableSize) { _, _ in recalculateFontSize() }
    }

    private var textAreaSize: CGSize {
        CGSize(
            width: max(availableSize.width - contentPadding * 2, 0),
            height: max(availableSize.height - contentPadding * 2, 0)
        )
    }

    private func recalculateFontSize() {
        let target = FittingFontSizeCalculator.fittingSize(
            text: text,
            in: textAreaSize,
            min: minFontSize,
            max: maxFontSize
        )
        if fontSize != target {
            fontSize = target
        }
    }
}
