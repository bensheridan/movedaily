import SwiftUI

// MARK: - App Icon View
//
// This view defines the app icon design.
// Run `swift tools/generate-icons.swift` from the repo root to export PNG assets.

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.55, blue: 0.0),
                    Color(red: 0.9, green: 0.3, blue: 0.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle inner glow ring
            Circle()
                .fill(Color.white.opacity(0.08))
                .scaleEffect(0.85)

            // Movement figure
            Image(systemName: "figure.run")
                .font(.system(size: 420, weight: .bold))
                .foregroundStyle(.white.opacity(0.95))
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                .offset(x: 20)
        }
    }
}

// MARK: - Preview

#Preview("Icon — 1024×1024") {
    AppIconView()
        .frame(width: 1024, height: 1024)
        .clipShape(RoundedRectangle(cornerRadius: 224, style: .continuous))
        .previewLayout(.sizeThatFits)
}

#Preview("Icon — Home Screen Size") {
    AppIconView()
        .frame(width: 180, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        .previewLayout(.sizeThatFits)
}
