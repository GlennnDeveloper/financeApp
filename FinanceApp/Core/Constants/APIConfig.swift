import Foundation
import Combine

/// Access to configuration environment variables from .xcconfig files via Info.plist
struct APIConfig {
    enum ConfigError: Error {
        case missingKey, invalidValue
    }
    
    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
            throw ConfigError.missingKey
        }
        
        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            throw ConfigError.invalidValue
        }
    }
    
    static var baseURL: URL {
        let string: String = (try? value(for: "BASE_URL")) ?? "https://api.example.com"
        return URL(string: string)!
    }
    
    static var supabaseURL: URL {
        let string: String = (try? value(for: "SUPABASE_URL")) ?? "https://example.supabase.co"
        return URL(string: string)!
    }
    
    static var apiKey: String {
        return (try? value(for: "API_KEY")) ?? ""
    }
}
