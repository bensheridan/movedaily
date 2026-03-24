import SwiftUI

// MARK: - Design Tokens

struct DesignTokens {
    static let cardCornerRadius: CGFloat = 20
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowOpacity: Double = 0.08
    static let cardShadowOffset: CGSize = CGSize(width: 0, height: 4)
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    static let gridSpacing: CGFloat = 15
    static let scaleButton = ScaleButtonStyle()
}

// MARK: - Card Modifier

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous)
                    .stroke(Color(uiColor: .separator).opacity(0.5), lineWidth: 0.5)
            )
            .shadow(
                color: Color.black.opacity(DesignTokens.cardShadowOpacity),
                radius: DesignTokens.cardShadowRadius,
                x: DesignTokens.cardShadowOffset.width,
                y: DesignTokens.cardShadowOffset.height
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

        VStack(spacing: DesignTokens.sectionSpacing) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Style")
                    .font(.headline)
                Text("Uses .regularMaterial background, rounded corners, subtle border and shadow.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(DesignTokens.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()

            Button("Scale Button Style") {}
                .buttonStyle(DesignTokens.scaleButton)
                .padding(DesignTokens.cardPadding)
                .frame(maxWidth: .infinity)
                .cardStyle()
        }
        .padding()
    }
}
