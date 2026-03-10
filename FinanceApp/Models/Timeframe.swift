import Foundation

enum Timeframe: String, CaseIterable, Codable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    var localizedName: String {
        SettingsManager.shared.localizedString(for: self.rawValue)
    }
}
