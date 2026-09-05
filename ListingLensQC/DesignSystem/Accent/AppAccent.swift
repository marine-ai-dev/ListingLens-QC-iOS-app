import SwiftUI

/// Semantic accent tokens. Screens reference `AppAccent.primary` etc., never a raw hex
/// or system color, so retinting or swapping in a shared DesignKit is a one-file change.
public enum AppAccent: String, CaseIterable, Identifiable, Codable, Sendable {
    case lens // default: a calm blue-teal referencing the "lens" in the app name
    case amber
    case violet

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .lens: return Color(red: 0.15, green: 0.55, blue: 0.62)
        case .amber: return Color(red: 0.85, green: 0.55, blue: 0.15)
        case .violet: return Color(red: 0.48, green: 0.4, blue: 0.78)
        }
    }
}
