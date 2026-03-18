import SwiftUI
import Combine



enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case spanish = "Español"
    
    var id: String { self.rawValue }
    
    var localeIdentifier: String {
        switch self {
        case .english: return "en"
        case .spanish: return "es"
        }
    }
    
    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }
}

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @AppStorage("app_language") var appLanguageName: String = AppLanguage.english.rawValue
    @AppStorage("app_currency") var appCurrency: String = "USD"
    @AppStorage("use_biometrics") var useBiometrics: Bool = false
    @AppStorage("is_premium") var isPremium: Bool = false
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    // Tracks whether any bank accounts are linked via Plaid.
    @AppStorage("isBankConnected") var isBankConnected: Bool = false
    @AppStorage("has_completed_onboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("user_name") var userName: String = ""
    @AppStorage("user_age") var userAge: Int = 0
    @AppStorage("show_diagnostics") var showDiagnostics: Bool = false
    @AppStorage("financial_goals") var financialGoalsData: Data = Data()

    var financialGoals: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: financialGoalsData)) ?? []
        }
        set {
            financialGoalsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    

    var appLanguage: AppLanguage {
        get { AppLanguage(rawValue: appLanguageName) ?? .english }
        set { appLanguageName = newValue.rawValue }
    }
    
    var locale: Locale {
        appLanguage.locale
    }
    
    func localizedString(for key: String) -> String {
        guard let path = Bundle.main.path(forResource: appLanguage.localeIdentifier, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
    
    func reset() {
        isPremium = false
        isLoggedIn = false
        isBankConnected = false
        hasCompletedOnboarding = false
        userName = ""
        userAge = 0
        financialGoals = []
        // Optional: appCurrency = "USD"
    }
    
    private init() {}
}
