import Foundation

/// Single source of truth for the app's version/build, read from the bundle so the
/// displayed version can never drift from what shipped. Used by the Profile footer,
/// the data export, and the feedback payload.
enum AppInfo {
    /// Marketing version, e.g. "1.0".
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    /// Build number, e.g. "1".
    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    /// "1.0 (1)" — version with build, for diagnostics/export.
    static var versionWithBuild: String { "\(version) (\(build))" }

    /// "Forge v1.0" — the user-facing short label.
    static var shortLabel: String { "Forge v\(version)" }
}
