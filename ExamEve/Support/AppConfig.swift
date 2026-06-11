import Foundation

/// Build-time configuration. Values are read from Info.plist (injected by Secrets.xcconfig at build
/// time) and fall back to the defaults below so the project builds out-of-the-box.
enum AppConfig {
    static let supabaseURL = string("SupabaseURL") ?? "https://dwzrgzobiqhrqxjxteyu.supabase.co"
    static let supabaseKey = string("SupabaseKey") ?? "sb_publishable_j8mJNOyxxirJMHrx_KHX5g_qQJZkRQO"

    private static func string(_ key: String) -> String? {
        guard let v = Bundle.main.object(forInfoDictionaryKey: key) as? String, !v.isEmpty else { return nil }
        return v
    }
}
