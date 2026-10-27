import SwiftUI

// MARK: - Fold-Aware Layout

/// Folded (iPhone Duo cover screen, any iPhone) the horizontal size class is compact and
/// the app keeps its phone layouts. Unfolded (Duo inner screen, iPad) it is regular and the
/// main screens spread into side-by-side columns.
extension EnvironmentValues {
    /// True when there's room for side-by-side columns (regular width).
    @Entry var isUnfolded = false
}

/// Fixed-width leading column next to a flexible trailing column, used for
/// list + detail panes on the unfolded screen.
struct SideBySide<Leading: View, Trailing: View>: View {
    var leadingWidth: CGFloat = 340
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 0) {
            leading()
                .frame(width: leadingWidth)
            Divider()
                .ignoresSafeArea(edges: .bottom)
            trailing()
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview("Side by Side") {
    SideBySide {
        List(1..<6) { Text("Row \($0)") }
    } trailing: {
        Text("Detail")
    }
    .frame(width: 900, height: 600)
}
