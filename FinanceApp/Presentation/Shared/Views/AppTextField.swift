import SwiftUI

/// Standardized text field with icon and focus styling.
struct AppTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var isFocused: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var onSubmit: (() -> Void)? = nil
    
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundStyle(isFocused ? .orange : .white.opacity(0.4))
                .font(.system(size: 20))
                .frame(width: 24)
            
            if isSecure {
                SecureField("", text: $text, prompt: Text(settingsManager.localizedString(for: placeholder)).foregroundStyle(.white.opacity(0.3)))
                    .foregroundStyle(.white)
                    .textContentType(textContentType)
                    .onSubmit { onSubmit?() }
            } else {
                TextField("", text: $text, prompt: Text(settingsManager.localizedString(for: placeholder)).foregroundStyle(.white.opacity(0.3)))
                    .foregroundStyle(.white)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .onSubmit { onSubmit?() }
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 64)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isFocused ? .white.opacity(0.12) : .white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isFocused ? .orange.opacity(0.5) : .clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    VStack(spacing: 16) {
        AppTextField(icon: "envelope.fill", placeholder: "Email", text: .constant(""), isFocused: true)
        AppTextField(icon: "lock.fill", placeholder: "Password", text: .constant(""), isSecure: true)
    }
    .padding()
    .background(Color.black.opacity(0.9))
    .environmentObject(SettingsManager.shared)
}
