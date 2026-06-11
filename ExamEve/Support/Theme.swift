import SwiftUI

// MARK: - 프로필 색상 팔레트

enum ProfileColor: String, CaseIterable {
    case sky      = "sky"
    case pink     = "pink"
    case mint     = "mint"
    case lavender = "lavender"
    case peach    = "peach"

    var color: Color {
        switch self {
        case .sky:      return Color(red: 200/255, green: 228/255, blue: 255/255)
        case .pink:     return Color(red: 255/255, green: 214/255, blue: 232/255)
        case .mint:     return Color(red: 197/255, green: 245/255, blue: 232/255)
        case .lavender: return Color(red: 232/255, green: 213/255, blue: 255/255)
        case .peach:    return Color(red: 255/255, green: 232/255, blue: 200/255)
        }
    }

    static func resolve(_ key: String?) -> Color {
        ProfileColor(rawValue: key ?? "sky")?.color ?? ProfileColor.sky.color
    }
}

extension Color {
    /// Quizlet 시그니처 블루 (#4255FF)
    static let appPrimary = Color(red: 66 / 255, green: 85 / 255, blue: 255 / 255)
    static let appBackground = Color(red: 246 / 255, green: 247 / 255, blue: 251 / 255)
    static let appYellow = Color(red: 255 / 255, green: 205 / 255, blue: 66 / 255)
    static let appGreen = Color(red: 35 / 255, green: 181 / 255, blue: 116 / 255)
    static let appRed = Color(red: 255 / 255, green: 92 / 255, blue: 92 / 255)
    static let appPurple = Color(red: 124 / 255, green: 92 / 255, blue: 255 / 255)
    static let appTeal = Color(red: 24 / 255, green: 174 / 255, blue: 188 / 255)
    static let appOrange = Color(red: 255 / 255, green: 144 / 255, blue: 64 / 255)
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}

struct PrimaryButton: View {
    let title: String
    var disabled = false
    var busy = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(busy ? 0 : 1)
                if busy { ProgressView().tint(.white) }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(disabled ? Color.gray.opacity(0.35) : Color.appPrimary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(disabled || busy)
    }
}

struct TagChip: View {
    let text: String
    var color: Color = .appPrimary

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct RoundedField: View {
    let placeholder: String
    @Binding var text: String
    var secure = false

    var body: some View {
        Group {
            if secure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}
