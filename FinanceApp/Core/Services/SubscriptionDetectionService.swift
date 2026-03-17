import Foundation

struct SubscriptionDetectionService {
    
    /// Analyzes a list of transactions and identifies which ones are likely recurring.
    /// - Parameter transactions: The list of transactions to analyze.
    /// - Returns: A set of UUIDs of transactions that are detected as recurring.
    static func detectRecurringPatterns(in transactions: [Transaction]) -> Set<UUID> {
        let calendar = Calendar.current
        var recurringIds = Set<UUID>()
        
        // Group by title (normalized)
        let grouped = Dictionary(grouping: transactions) { $0.title.lowercased().trimmingCharacters(in: .whitespaces) }
        
        let blacklist = ["uber", "lyft", "starbucks", "amazon", "apple store", "gas", "shell", "chevron", "mcdonald", "restaurant", "pharmacy", "grocery"]
        
        for (title, group) in grouped {
            // 1. Minimum occurrences: require at least 3 for most things to be sure
            // or 2 if it's a very specific amount pattern and not in blacklist
            guard group.count >= 2 else { continue }
            
            // 2. Blacklist check: If it's a known one-off service, be extremely skeptical
            let isBlacklisted = blacklist.contains { title.contains($0) }
            if isBlacklisted && group.count < 4 { continue } // Require 4+ months for blacklisted keywords
            
            let sortedGroup = group.sorted { $0.date < $1.date }
            
            // Check for monthly or weekly patterns
            var isPatternFound = false
            
            // 1. Check for monthly pattern (approx 28-31 days apart)
            // Or same day of month (+/- 2 days)
            for i in 0..<sortedGroup.count - 1 {
                let tx1 = sortedGroup[i]
                let tx2 = sortedGroup[i+1]
                
                let components = calendar.dateComponents([.day], from: tx1.date, to: tx2.date)
                let dayDiff = abs(components.day ?? 0)
                
                // Monthly range: 25 to 35 days
                // Weekly range: 6 to 8 days
                let isMonthly = dayDiff >= 25 && dayDiff <= 35
                let isWeekly = dayDiff >= 6 && dayDiff <= 8
                
                // Amount similarity (within 5% or exactly same)
                let amountMatch = abs(tx1.amount - tx2.amount) <= (tx1.amount * 0.05)
                
                if (isMonthly || isWeekly) && amountMatch {
                    isPatternFound = true
                    break
                }
            }
            
            if isPatternFound {
                // Mark all transactions in this group as recurring if they fit the pattern
                // For simplicity, if we found a pattern in the group, we mark the group members.
                // A more advanced version would filter out outliers.
                for tx in group {
                    recurringIds.insert(tx.id)
                }
            }
        }
        
        return recurringIds
    }
}
