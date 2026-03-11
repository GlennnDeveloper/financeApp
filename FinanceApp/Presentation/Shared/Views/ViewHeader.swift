import SwiftUI

struct ViewHeader: View {
    @EnvironmentObject var settingsManager: SettingsManager
    let title: String
    @Binding var showSettings: Bool
    var rightContent: AnyView? = nil

    var body: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showSettings.toggle()
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundStyle(.gray)
            }

            Spacer()

            Text(settingsManager.localizedString(for: title))
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            if let rightContent = rightContent {
                rightContent
            } else {
                // Placeholder to keep the title centered
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundStyle(.clear)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}
