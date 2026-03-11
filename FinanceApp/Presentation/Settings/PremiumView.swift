import SwiftUI

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.yellow.opacity(0.15))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.yellow)
                    }
                    
                    VStack(spacing: 8) {
                        Text(SettingsManager.shared.localizedString(for: "FinanceApp Premium"))
                            .font(.title.bold())
                        
                        Text(SettingsManager.shared.localizedString(for: "Take control of your financial future"))
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 40)
                
                // Features
                VStack(spacing: 20) {
                    FeatureRow(icon: "chart.pie.fill", color: .purple, title: "Advanced Analytics", description: "Deep dive into your spending habits with AI-powered insights.")
                    FeatureRow(icon: "arrow.left.arrow.right.circle.fill", color: .blue, title: "Unlimited Sync", description: "Connect all your bank accounts and credit cards automatically.")
                    FeatureRow(icon: "bell.badge.fill", color: .red, title: "Smart Alerts", description: "Get notified before you overspend or when subscriptions increase.")
                    FeatureRow(icon: "lock.shield.fill", color: .green, title: "Enhanced Security", description: "Extra layer of protection for your sensitive financial data.")
                }
                .padding(.horizontal)
                
                // Pricing / CTA
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text(SettingsManager.shared.localizedString(for: "$9.99 / month"))
                            .font(.title3.bold())
                        Text(SettingsManager.shared.localizedString(for: "Cancel anytime. No hidden fees."))
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    
                    Button {
                        // Action for subscription
                    } label: {
                        Text(SettingsManager.shared.localizedString(for: "Start 7-Day Free Trial"))
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.yellow, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemBackground))
    }
}

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(SettingsManager.shared.localizedString(for: title))
                    .font(.headline)
                Text(SettingsManager.shared.localizedString(for: description))
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        PremiumView()
    }
}
