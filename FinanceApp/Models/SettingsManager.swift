import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { self.rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case spanish = "Español"
    case french = "Français"
    case german = "Deutsch"
    case italian = "Italiano"
    
    var id: String { self.rawValue }
    
    var localeIdentifier: String {
        switch self {
        case .english: return "en"
        case .spanish: return "es"
        case .french: return "fr"
        case .german: return "de"
        case .italian: return "it"
        }
    }
    
    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }
}

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @AppStorage("app_theme") var appThemeName: String = AppTheme.system.rawValue
    @AppStorage("app_language") var appLanguageName: String = AppLanguage.english.rawValue
    @AppStorage("app_currency") var appCurrency: String = "USD"
    @AppStorage("use_biometrics") var useBiometrics: Bool = true
    
    var appTheme: AppTheme {
        get { AppTheme(rawValue: appThemeName) ?? .system }
        set { appThemeName = newValue.rawValue }
    }
    
    var appLanguage: AppLanguage {
        get { AppLanguage(rawValue: appLanguageName) ?? .english }
        set { appLanguageName = newValue.rawValue }
    }
    
    var locale: Locale {
        appLanguage.locale
    }
    
    private init() {}
}
