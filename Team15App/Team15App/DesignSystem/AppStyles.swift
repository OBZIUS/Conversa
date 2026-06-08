import SwiftUI

// MARK: - Color Palette

enum AppColors {
    static let navy      = Color(hex: "#19196E")
    static let orange    = Color(hex: "#FF9B21")
    static let lightBlue = Color(hex: "#3D5AFE")
    static let subtitle  = Color(hex: "#666666")
    static let fieldBg   = Color(hex: "#F5F5F5")
    static let border    = Color(hex: "#D0D0D0")
    static let dashedBox = Color(hex: "#E8EAFF")
    static let pdfRed    = Color(hex: "#E53935")
    static let successGreen = Color(hex: "#2E7D32")
    static let cardBg    = Color(hex: "#F8F8FF")
    static let ticketBg  = Color(hex: "#F2F4FF")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var backgroundColor: Color = AppColors.orange
    var foregroundColor: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundColor)
            .cornerRadius(28)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct NavyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(AppColors.navy)
            .cornerRadius(24)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Shared Field Style

struct FormFieldLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(AppColors.subtitle)
    }
}

// MARK: - Editable Ticket Field

struct TicketField: View {
    let label: String
    @Binding var value: String
    var placeholder: String = ""

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.subtitle)

            TextField(placeholder.isEmpty ? label : placeholder, text: $value)
                .font(.system(size: 15))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFocused ? AppColors.lightBlue : AppColors.border, lineWidth: isFocused ? 2 : 1)
                )
                .focused($isFocused)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

// MARK: - Dropdown Picker Row

struct FormPickerRow: View {
    let label: String
    let placeholder: String
    let options: [String]
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FormFieldLabel(text: label)
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    Text(selection.isEmpty ? placeholder : selection)
                        .font(.system(size: 15))
                        .foregroundColor(selection.isEmpty ? Color(UIColor.placeholderText) : AppColors.navy)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.subtitle)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(AppColors.fieldBg)
                .cornerRadius(30)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(AppColors.border, lineWidth: 1)
                )
            }
            .foregroundColor(AppColors.navy)
        }
    }
}

// MARK: - Back Button

struct BackButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(AppColors.border, lineWidth: 1)
                    .frame(width: 38, height: 38)
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.navy)
            }
        }
    }
}

// MARK: - Postage Stamp / Scalloped Card Shape

struct ScallopedCardShape: Shape {
    var scallopRadius: CGFloat = 4
    var scallopSpacing: CGFloat = 12

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY
        
        // Start top-left
        path.move(to: CGPoint(x: minX, y: minY))
        
        // Top edge: left to right
        let topCount = Int((rect.width - 2 * scallopRadius) / scallopSpacing)
        let topStep = (rect.width - 2 * scallopRadius) / CGFloat(topCount)
        for i in 0..<topCount {
            let x = minX + scallopRadius + CGFloat(i) * topStep
            path.addLine(to: CGPoint(x: x, y: minY))
            path.addArc(center: CGPoint(x: x + topStep/2, y: minY), radius: scallopRadius, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
        }
        path.addLine(to: CGPoint(x: maxX, y: minY))
        
        // Right edge: top to bottom
        let rightCount = Int((rect.height - 2 * scallopRadius) / scallopSpacing)
        let rightStep = (rect.height - 2 * scallopRadius) / CGFloat(rightCount)
        for i in 0..<rightCount {
            let y = minY + scallopRadius + CGFloat(i) * rightStep
            path.addLine(to: CGPoint(x: maxX, y: y))
            path.addArc(center: CGPoint(x: maxX, y: y + rightStep/2), radius: scallopRadius, startAngle: .degrees(270), endAngle: .degrees(90), clockwise: true)
        }
        path.addLine(to: CGPoint(x: maxX, y: maxY))
        
        // Bottom edge: right to left
        let bottomCount = Int((rect.width - 2 * scallopRadius) / scallopSpacing)
        let bottomStep = (rect.width - 2 * scallopRadius) / CGFloat(bottomCount)
        for i in 0..<bottomCount {
            let x = maxX - scallopRadius - CGFloat(i) * bottomStep
            path.addLine(to: CGPoint(x: x, y: maxY))
            path.addArc(center: CGPoint(x: x - bottomStep/2, y: maxY), radius: scallopRadius, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: true)
        }
        path.addLine(to: CGPoint(x: minX, y: maxY))
        
        // Left edge: bottom to top
        let leftCount = Int((rect.height - 2 * scallopRadius) / scallopSpacing)
        let leftStep = (rect.height - 2 * scallopRadius) / CGFloat(leftCount)
        for i in 0..<leftCount {
            let y = maxY - scallopRadius - CGFloat(i) * leftStep
            path.addLine(to: CGPoint(x: minX, y: y))
            path.addArc(center: CGPoint(x: minX, y: y - leftStep/2), radius: scallopRadius, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: true)
        }
        path.addLine(to: CGPoint(x: minX, y: minY))
        
        path.closeSubpath()
        return path
    }
}

struct ScallopedCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                ScallopedCardShape()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            )
            .overlay(
                ScallopedCardShape()
                    .stroke(AppColors.border.opacity(0.5), lineWidth: 1)
                    .allowsHitTesting(false)
            )
    }
}

// MARK: - Dashed Divider

struct DashDivider: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: geo.size.width, y: 0))
            }
            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
            .foregroundColor(AppColors.border)
        }
        .frame(height: 1)
    }
}
