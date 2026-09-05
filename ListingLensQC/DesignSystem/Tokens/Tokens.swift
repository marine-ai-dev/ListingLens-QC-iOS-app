import SwiftUI

/// Spacing, radius, and minimum touch target tokens shared by all components.
public enum Spacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
}

public enum Radius {
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
}

public enum Metrics {
    /// Apple HIG minimum comfortable touch target.
    public static let minTouchTarget: CGFloat = 44
}

public enum StatusColor {
    public static let good = Color(red: 0.2, green: 0.65, blue: 0.35)
    public static let warning = Color(red: 0.85, green: 0.6, blue: 0.1)
    public static let critical = Color(red: 0.8, green: 0.25, blue: 0.25)
}
