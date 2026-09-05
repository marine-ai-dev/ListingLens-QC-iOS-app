import SwiftUI

/// Local, temporary design-system boundary. This folder is structured so a future
/// shared `DesignKit` repository could replace it wholesale — screens only ever import
/// the semantic tokens/components declared here, never raw SwiftUI colors/fonts.
public enum AppAppearance: String, CaseIterable, Identifiable, Codable, Sendable {
    case system, light, dark, black // black = true OLED black

    public var id: String { rawValue }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark, .black: return .dark
        }
    }
}

/// Persists the user's chosen appearance locally (UserDefaults-backed), independent of
/// any accounts/analytics — purely a local UI preference.
@MainActor
public final class AppTheme: ObservableObject {
    private static let key = "listinglensqc.appearance"
    private static let accentKey = "listinglensqc.accent"

    @Published public var appearance: AppAppearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Self.key) }
    }

    @Published public var selectedAccent: AppAccent {
        didSet { UserDefaults.standard.set(selectedAccent.rawValue, forKey: Self.accentKey) }
    }

    public init() {
        let stored = UserDefaults.standard.string(forKey: Self.key)
        self.appearance = stored.flatMap(AppAppearance.init(rawValue:)) ?? .system
        let storedAccent = UserDefaults.standard.string(forKey: Self.accentKey)
        self.selectedAccent = storedAccent.flatMap(AppAccent.init(rawValue:)) ?? .lens
    }

    public var backgroundColor: Color {
        #if canImport(UIKit)
        appearance == .black ? .black : Color(uiColor: .systemBackground)
        #else
        appearance == .black ? .black : Color.white
        #endif
    }
}
