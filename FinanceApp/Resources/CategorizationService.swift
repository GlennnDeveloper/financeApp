import Foundation

/// Helper to map Plaid categories and titles to app categories
struct CategorizationService {
    
    /// Maps a transaction title and Plaid categories to one of our internal symbols
    static func mapCategory(title: String, plaidCategories: [String]?) -> String {
        let lowercaseTitle = title.lowercased()
        
        // 1. Title-based mapping (very common stores/services)
        
        // Food & Drink (fork.knife) -> "orange"
        if lowercaseTitle.contains("starbucks") || lowercaseTitle.contains("mcdonald") || lowercaseTitle.contains("restaurant") || lowercaseTitle.contains("ubereats") || lowercaseTitle.contains("doordash") || lowercaseTitle.contains("grocery") || lowercaseTitle.contains("supermarket") || lowercaseTitle.contains("cafe") {
            return "fork.knife"
        }
        
        // Transport (bus.fill) -> "blue"
        if lowercaseTitle.contains("uber") || lowercaseTitle.contains("lyft") || lowercaseTitle.contains("gas") || lowercaseTitle.contains("shell") || lowercaseTitle.contains("chevron") || lowercaseTitle.contains("transit") || lowercaseTitle.contains("mta") || lowercaseTitle.contains("metro") {
            return "bus.fill"
        }
        
        // Home Bills (bolt.fill) -> "orange"
        if lowercaseTitle.contains("electric") || lowercaseTitle.contains("water") || lowercaseTitle.contains("internet") || lowercaseTitle.contains("comcast") || lowercaseTitle.contains("at&t") || lowercaseTitle.contains("verizon") || lowercaseTitle.contains("rent") || lowercaseTitle.contains("mortgage") {
            return "bolt.fill"
        }
        
        // Self-Care (sparkles) -> "purple"
        if lowercaseTitle.contains("salon") || lowercaseTitle.contains("spa") || lowercaseTitle.contains("massage") || lowercaseTitle.contains("barber") || lowercaseTitle.contains("nails") || lowercaseTitle.contains("hair") {
            return "sparkles"
        }
        
        // Shopping (bag.fill) -> "red"
        if lowercaseTitle.contains("amazon") || lowercaseTitle.contains("target") || lowercaseTitle.contains("walmart") || lowercaseTitle.contains("apple") || lowercaseTitle.contains("zara") || lowercaseTitle.contains("nike") || lowercaseTitle.contains("clothing") || lowercaseTitle.contains("mall") {
            return "bag.fill"
        }
        
        // Health (cross.case.fill) -> "teal"
        if lowercaseTitle.contains("pharmacy") || lowercaseTitle.contains("walgreens") || lowercaseTitle.contains("cvs") || lowercaseTitle.contains("hospital") || lowercaseTitle.contains("doctor") || lowercaseTitle.contains("dental") || lowercaseTitle.contains("gym") || lowercaseTitle.contains("fitness") || lowercaseTitle.contains("planet fitness") {
            return "cross.case.fill"
        }
        
        // Salary (banknote.fill) -> "green"
        if lowercaseTitle.contains("salary") || lowercaseTitle.contains("paycheck") || lowercaseTitle.contains("payroll") || lowercaseTitle.contains("deposit") || lowercaseTitle.contains("dividend") {
            return "banknote.fill"
        }
        
        // 2. Plaid category-based mapping fallback
        if let categories = plaidCategories {
            for category in categories {
                let lowerCategory = category.lowercased()
                
                if lowerCategory.contains("food") || lowerCategory.contains("dining") || lowerCategory.contains("grocery") {
                    return "fork.knife"
                }
                
                if lowerCategory.contains("travel") || lowerCategory.contains("transport") {
                    return "bus.fill"
                }
                
                if lowerCategory.contains("health") || lowerCategory.contains("medical") || lowerCategory.contains("pharmacy") || lowerCategory.contains("fitness") {
                    return "cross.case.fill"
                }
                
                if lowerCategory.contains("shops") || lowerCategory.contains("shopping") || lowerCategory.contains("clothing") || lowerCategory.contains("department") {
                    return "bag.fill"
                }
                
                if lowerCategory.contains("personal care") {
                    return "sparkles"
                }
                
                if lowerCategory.contains("utilities") || lowerCategory.contains("bills") {
                    return "bolt.fill"
                }
                
                if lowerCategory.contains("income") || lowerCategory.contains("transfer") || lowerCategory.contains("payroll") {
                    return "banknote.fill"
                }
            }
        }
        
        // Default "Others"
        return "ellipsis.circle.fill"
    }
}
