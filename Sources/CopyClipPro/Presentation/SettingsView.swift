import SwiftUI

/// Cửa sổ cài đặt (MVP): retention, quyền riêng tư, hành vi dán.
struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    /// Cho biết trạng thái quyền Accessibility (để tự động dán).
    var accessibilityGranted: Bool
    var onRequestAccessibility: () -> Void

    var body: some View {
        Form {
            Section("Lịch sử") {
                Stepper(
                    "Giữ tối đa \(settings.maxHistoryItems) mục",
                    value: $settings.maxHistoryItems,
                    in: 50...100_000,
                    step: 50
                )
            }

            Section("Quyền riêng tư") {
                Toggle("Bỏ qua nội dung ẩn (mật khẩu, OTP)", isOn: $settings.ignoreConcealed)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ứng dụng bị bỏ qua (bundle id, cách nhau bằng dấu phẩy)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("com.apple.keychainaccess, …", text: $settings.ignoredBundleIdsRaw)
                        .textFieldStyle(.roundedBorder)
                }
            }

            Section("Dán") {
                Toggle("Tự động dán sau khi chọn (Cmd+V)", isOn: $settings.pasteOnSelect)
                if settings.pasteOnSelect {
                    HStack {
                        Image(systemName: accessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(accessibilityGranted ? .green : .orange)
                        Text(accessibilityGranted
                             ? "Đã cấp quyền Accessibility"
                             : "Cần quyền Accessibility để tự động dán")
                            .font(.caption)
                        Spacer()
                        if !accessibilityGranted {
                            Button("Cấp quyền", action: onRequestAccessibility)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 380)
    }
}
