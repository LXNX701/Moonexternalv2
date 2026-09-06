import SwiftUI

// MARK: - Tema existente (preservado al 100%)
enum AppTheme {
    static let accent = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 1.00, green: 0.64, blue: 0.42, alpha: 1.00)
                : UIColor(red: 0.85, green: 0.42, blue: 0.20, alpha: 1.00)
        }
    )
    static let pageBackground = Color(uiColor: .systemBackground)
    static let consoleBackground = Color(uiColor: .secondarySystemBackground)
    static let pageInset: CGFloat = 16
    static let rowIconSize: CGFloat = 17
    static let rowIconFrame: CGFloat = 28
    static let fileRowIconSize: CGFloat = 17
    static let fileRowIconFrame: CGFloat = 30
    static let fileRowHeight: CGFloat = 60
    static let appIconSize: CGFloat = 32
    static let emptyIconSize: CGFloat = 30
    static let selectionIconSize: CGFloat = 18
}

// MARK: - Componentes existentes (preservados)
struct AppRowIcon: View {
    let systemName: String
    var tint: Color = AppTheme.accent
    var symbolSize: CGFloat = AppTheme.rowIconSize
    var frameSize: CGFloat = AppTheme.rowIconFrame

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(tint.opacity(0.12))
            Image(systemName: systemName)
                .font(.system(size: symbolSize, weight: .medium))
                .foregroundStyle(tint)
        }
        .frame(width: frameSize, height: frameSize)
        .accessibilityHidden(true)
    }
}

struct AppSearchField: View {
    @Binding var text: String
    let prompt: String
    let clearLabel: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(prompt, text: $text)
                .font(.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(clearLabel)
            }
        }
        .padding(.horizontal, 11)
        .frame(minHeight: 36)
        .background(
            Color(uiColor: .secondarySystemFill),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .padding(.horizontal, AppTheme.pageInset)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

struct AppLogo: View {
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let icon = UIImage(named: "AppIcon60x60")
                ?? Bundle.main.path(forResource: "AppIcon60x60@2x", ofType: "png").flatMap(UIImage.init(contentsOfFile:))
                ?? UIImage(named: "AppIcon") {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.accent)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .accessibilityHidden(true)
    }
}

// MARK: - NUEVOS ESTILOS PARA "MOONZAZA x Cheat"
extension Color {
    static let moonPrimary = Color(hex: "#6C2BD9")      // Morado principal
    static let moonSecondary = Color(hex: "#FF3B30")    // Rojo
    static let moonBackground = Color(hex: "#0A0A0A")   // Negro
    static let moonCard = Color(hex: "#1A1A1A")         // Fondo de tarjetas
    static let moonBorder = Color(hex: "#6C2BD9").opacity(0.3)
    static let moonGlow = Color(hex: "#6C2BD9").opacity(0.2)
}

extension LinearGradient {
    static let moonGradient = LinearGradient(
        colors: [.moonPrimary, .moonSecondary],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let moonGradientVertical = LinearGradient(
        colors: [.moonPrimary, .moonSecondary],
        startPoint: .top,
        endPoint: .bottom
    )

    static let moonBackgroundGradient = LinearGradient(
        colors: [.moonBackground, .moonPrimary.opacity(0.3)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Estilos de texto
extension Text {
    func moonTitleStyle() -> some View {
        self
            .font(.title2.weight(.bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [.moonPrimary, .moonSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }

    func moonSubtitleStyle() -> some View {
        self
            .font(.subheadline)
            .foregroundColor(.gray)
    }

    func moonStatusStyle(color: Color) -> some View {
        self
            .font(.caption.weight(.semibold))
            .foregroundColor(color)
    }
}

// MARK: - Botón personalizado
struct MoonButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                LinearGradient.moonGradient
                    .opacity(configuration.isPressed ? 0.7 : 1)
            )
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(color: .moonPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Estilo de tarjeta
struct MoonCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .background(Color.moonCard.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.moonBorder, lineWidth: 1)
            )
            .shadow(color: .moonGlow, radius: 15, x: 0, y: 5)
    }
}

extension View {
    func moonCard() -> some View {
        modifier(MoonCardStyle())
    }

    func moonGradientText() -> some View {
        self.overlay(
            LinearGradient.moonGradient
                .mask(self)
        )
    }
}

// MARK: - Helper para Color desde hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}