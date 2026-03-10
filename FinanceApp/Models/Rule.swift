import Foundation
import SwiftData

@Model
final class Rule {
    var id: UUID
    var pattern: String // The string to match in transaction titles
    var categorySymbol: String // The symbol to assign if matched
    
    init(id: UUID = UUID(), pattern: String, categorySymbol: String) {
        self.id = id
        self.pattern = pattern
        self.categorySymbol = categorySymbol
    }
}
