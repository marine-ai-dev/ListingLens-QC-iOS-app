import SwiftUI

@main
struct ListingLensQCApp: App {
    @StateObject private var theme = AppTheme()

    var body: some Scene {
        WindowGroup {
            ImportView()
                .environmentObject(theme)
                .preferredColorScheme(theme.appearance.colorScheme)
                .background(theme.backgroundColor.ignoresSafeArea())
        }
    }
}
