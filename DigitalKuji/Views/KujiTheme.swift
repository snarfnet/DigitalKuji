import SwiftUI

enum KujiTheme {
    static let ink = Color(red: 0.14, green: 0.11, blue: 0.09)
    static let mutedInk = Color(red: 0.43, green: 0.37, blue: 0.31)
    static let vermilion = Color(red: 0.77, green: 0.12, blue: 0.09)
    static let deepRed = Color(red: 0.46, green: 0.04, blue: 0.03)
    static let gold = Color(red: 0.78, green: 0.58, blue: 0.24)
    static let paper = Color(red: 1.0, green: 0.97, blue: 0.91)
    static let paperLine = Color(red: 0.86, green: 0.76, blue: 0.58)
    static let softPanel = Color.white.opacity(0.76)

    static let cardGradient = LinearGradient(
        colors: [Color(red: 0.86, green: 0.14, blue: 0.10), Color(red: 0.48, green: 0.04, blue: 0.03)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldGradient = LinearGradient(
        colors: [Color(red: 0.98, green: 0.84, blue: 0.42), Color(red: 0.65, green: 0.42, blue: 0.12)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct OmikujiScreenBackground: View {
    var body: some View {
        ZStack {
            Image("OmikujiBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.white.opacity(0.30),
                    Color(red: 1.0, green: 0.96, blue: 0.88).opacity(0.70),
                    Color(red: 0.24, green: 0.03, blue: 0.02).opacity(0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

struct PaperPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(KujiTheme.softPanel)
                    .shadow(color: Color(red: 0.32, green: 0.12, blue: 0.04).opacity(0.12), radius: 18, y: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(KujiTheme.paperLine.opacity(0.55), lineWidth: 1)
                    )
            )
    }
}
