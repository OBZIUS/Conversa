import UIKit

enum FittingFontSizeCalculator {
    private static let heightSafety: CGFloat = 8
    private static let widthSafety: CGFloat = 4

    static func fittingSize(
        text: String,
        in size: CGSize,
        min minSize: CGFloat = 18,
        max maxSize: CGFloat = 80,
        weight: UIFont.Weight = .regular
    ) -> CGFloat {
        guard !text.isEmpty, size.width > 0, size.height > 0 else {
            return minSize
        }

        var low = minSize
        var high = maxSize

        while low < high {
            let mid = ceil((low + high) / 2)
            if textFits(text, fontSize: mid, in: size, weight: weight) {
                low = mid
            } else {
                high = mid - 1
            }
        }

        return low
    }

    private static func textFits(
        _ text: String,
        fontSize: CGFloat,
        in size: CGSize,
        weight: UIFont.Weight
    ) -> Bool {
        let measured = measuredBounds(text: text, fontSize: fontSize, width: size.width, weight: weight)
        let maxWidth = max(size.width - widthSafety, 0)
        let maxHeight = max(size.height - heightSafety, 0)
        return measured.width <= maxWidth && measured.height <= maxHeight
    }

    private static func measuredBounds(
        text: String,
        fontSize: CGFloat,
        width: CGFloat,
        weight: UIFont.Weight
    ) -> CGSize {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.systemFont(ofSize: fontSize, weight: weight)
        label.text = text
        return label.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }
}
