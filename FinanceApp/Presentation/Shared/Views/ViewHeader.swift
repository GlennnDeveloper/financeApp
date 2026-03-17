import SwiftUI

struct ViewHeader<RightContent: View>: View {
    @EnvironmentObject var settingsManager: SettingsManager
    let title: String
    @Binding var showSettings: Bool
    @ViewBuilder let rightContent: RightContent

    init(title: String, showSettings: Binding<Bool>, @ViewBuilder rightContent: () -> RightContent) {
        self.title = title
        self._showSettings = showSettings
        self.rightContent = rightContent()
    }

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

            rightContent
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
}

extension ViewHeader where RightContent == EmptyView {
    init(title: String, showSettings: Binding<Bool>) {
        self.init(title: title, showSettings: showSettings) {
            EmptyView()
        }
    }
}

extension ViewHeader where RightContent == AnyView {
    // Helper to keep the layout consistent when no right content is provided but we need a placeholder
    // though using EmptyView and Spacers is better.
    // Actually, let's just use the placeholder image if it's EmptyView.
}
