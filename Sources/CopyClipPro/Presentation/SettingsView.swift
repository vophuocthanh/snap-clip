import SwiftUI
import AppKit

/// Cửa sổ cài đặt.
struct SettingsView: View {
    @ObservedObject var settings: AppSettings
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

            Section("Bảo mật") {
                Toggle("Phát hiện & bỏ qua mật khẩu/OTP", isOn: $settings.ignoreConcealed)
                Toggle("Mã hoá nội dung nhạy cảm (AES-GCM)", isOn: $settings.encryptSensitiveContent)
                    .help("Lưu key trong Keychain, mã hoá field content bằng CryptoKit")
            }

            Section("Ứng dụng bị bỏ qua") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nhập bundle ID thủ công (cách nhau bằng phẩy):")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("com.apple.keychainaccess, …", text: $settings.ignoredBundleIdsRaw)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Hoặc chọn từ danh sách app đang chạy:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    let runningApps = NSWorkspace.shared.runningApplications
                        .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != nil }
                        .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }

                    ScrollView(.horizontal) {
                        HStack(spacing: 6) {
                            ForEach(runningApps, id: \.bundleIdentifier) { app in
                                let bundleId = app.bundleIdentifier ?? ""
                                let isSelected = settings.ignoredBundleIds.contains(bundleId)
                                Button {
                                    toggleAppIgnored(bundleId)
                                } label: {
                                    HStack(spacing: 4) {
                                        if let icon = app.icon {
                                            Image(nsImage: icon)
                                                .resizable()
                                                .frame(width: 14, height: 14)
                                        }
                                        Text(app.localizedName ?? bundleId)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(isSelected ? Color.red.opacity(0.15) : Color.secondary.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isSelected ? Color.red.opacity(0.4) : Color.clear, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(height: 32)
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
        .frame(width: 460, height: 520)
    }

    private func toggleAppIgnored(_ bundleId: String) {
        var ids = settings.ignoredBundleIds
        if ids.contains(bundleId) {
            ids.remove(bundleId)
        } else {
            ids.insert(bundleId)
        }
        settings.ignoredBundleIdsRaw = ids.sorted().joined(separator: ", ")
    }
}
