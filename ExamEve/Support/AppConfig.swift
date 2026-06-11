import Foundation

/// Build-time configuration. Values are injected via Secrets.xcconfig → build settings → Info.plist.
/// Falls back to hardcoded defaults so the project builds out-of-the-box after cloning.
enum AppConfig {
    // xcconfig에서 '//'가 주석으로 파싱되므로 호스트만 저장 후 여기서 URL을 조합합니다.
    static let supabaseURL: String = {
        if let host = string("SupabaseHost") {
            return "https://\(host)"
        }
        return "https://dwzrgzobiqhrqxjxteyu.supabase.co"
    }()

    static let supabaseKey: String = {
        string("SupabaseKey") ?? "sb_publishable_j8mJNOyxxirJMHrx_KHX5g_qQJZkRQO"
    }()

    private static func string(_ key: String) -> String? {
        guard let v = Bundle.main.object(forInfoDictionaryKey: key) as? String, !v.isEmpty else { return nil }
        return v
    }
}
