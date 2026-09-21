import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Bindable private var settings = SettingsManager.shared
    @State private var biometric = BiometricService()
    @State private var showClearConfirm = false
    @State private var exportFile: ExportFile?
    @State private var exportFailed = false
    @State private var permissionDenied = false
    @Environment(\.modelContext) private var modelContext
    @Query private var observations: [StarObservation]
    @Query private var achievements: [Achievement]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        profileCard
                        securityCard
                        notificationsCard
                        preferencesCard
                        dataCard
                        aboutCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .toolbarBackground(.hidden, for: .navigationBar)
            .themedToolbar()
            .confirmationDialog("Are you sure you want to delete all observations?",
                                isPresented: $showClearConfirm,
                                titleVisibility: .visible) {
                Button("Delete all", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $exportFile) { file in
                ShareSheet(items: [file.url])
            }
            .alert("Nothing to export", isPresented: $exportFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Log an observation first and it will appear in the CSV.")
            }
            .alert("Notifications are turned off", isPresented: $permissionDenied) {
                Button("Open Settings") { openSystemSettings() }
                Button("Not now", role: .cancel) {}
            } message: {
                Text("Allow notifications for StarGazer in iOS Settings to receive these alerts.")
            }
        }
    }

    // MARK: - Sections

    private var profileCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [ColorTheme.primaryAccent, ColorTheme.secondaryAccent],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundStyle(.black)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Username")
                    .font(.caption)
                    .foregroundStyle(ColorTheme.textSecondary)
                TextField("", text: $settings.username,
                          prompt: Text("Enter name").foregroundStyle(ColorTheme.textSecondary.opacity(0.6)))
                    .textFieldStyle(.plain)
                    .font(.title3.bold())
                    .foregroundStyle(ColorTheme.textPrimary)
            }
            Spacer()
        }
        .padding(16)
        .glassCard(cornerRadius: 18, tint: ColorTheme.primaryAccent)
    }

    private var securityCard: some View {
        VStack(spacing: 0) {
            sectionHeader("Security", icon: "lock.shield.fill")
            toggleRow(
                icon: "faceid",
                iconColor: .green,
                title: "Lock with \(biometric.biometryType() == .faceID ? "Face ID" : "Touch ID")",
                subtitle: biometric.biometryAvailable() ? "Requires authentication on launch" : "Not available on this device",
                isOn: $settings.faceIDEnabled,
                disabled: !biometric.biometryAvailable()
            )
        }
        .glassCardSection()
    }

    private var notificationsCard: some View {
        VStack(spacing: 0) {
            sectionHeader("Notifications", icon: "bell.fill")
            toggleRow(icon: "airplane", iconColor: .cyan, title: "ISS Passes",
                      subtitle: "When the ISS passes overhead", isOn: $settings.notifyISS)
            Divider().background(ColorTheme.stroke).padding(.leading, 60)
            toggleRow(icon: "moon.fill", iconColor: ColorTheme.secondaryAccent, title: "Moon phases",
                      subtitle: "Full and new moon", isOn: $settings.notifyMoon)
            Divider().background(ColorTheme.stroke).padding(.leading, 60)
            toggleRow(icon: "sparkles", iconColor: .purple, title: "Astronomical events",
                      subtitle: "Meteors, eclipses, conjunctions", isOn: $settings.notifyEvents)
        }
        .glassCardSection()
        .onChange(of: settings.notifyISS) { _, on in applyNotification(.iss, on) }
        .onChange(of: settings.notifyMoon) { _, on in applyNotification(.moon, on) }
        .onChange(of: settings.notifyEvents) { _, on in applyNotification(.events, on) }
    }

    private var preferencesCard: some View {
        VStack(spacing: 0) {
            sectionHeader("Preferences", icon: "slider.horizontal.3")
            pickerRow(icon: "ruler.fill", iconColor: .orange, title: "Units", selection: $settings.units) {
                ForEach(Units.allCases) { Text($0.label).tag($0) }
            }
            Divider().background(ColorTheme.stroke).padding(.leading, 60)
            pickerRow(icon: "paintbrush.fill", iconColor: .pink, title: "Theme", selection: $settings.theme) {
                ForEach(AppTheme.allCases) { Text($0.label).tag($0) }
            }
            Divider().background(ColorTheme.stroke).padding(.leading, 60)
            pickerRow(icon: "map.fill", iconColor: .green, title: "Map", selection: $settings.mapStyle) {
                ForEach(MapStyleOption.allCases) { Text($0.label).tag($0) }
            }
        }
        .glassCardSection()
    }

    private var dataCard: some View {
        VStack(spacing: 0) {
            sectionHeader("Data", icon: "externaldrive.fill")
            actionRow(icon: "square.and.arrow.up.fill", iconColor: .blue, title: "Export as CSV",
                      subtitle: "\(observations.count) observations") { exportCSV() }
            Divider().background(ColorTheme.stroke).padding(.leading, 60)
            actionRow(icon: "trash.fill", iconColor: ColorTheme.error,
                      title: "Delete all data", subtitle: "Cannot be undone", destructive: true) {
                showClearConfirm = true
            }
        }
        .glassCardSection()
    }

    private var aboutCard: some View {
        VStack(spacing: 0) {
            sectionHeader("About", icon: "info.circle.fill")
            infoRow(label: "Version", value: Self.appVersion)
            Divider().background(ColorTheme.stroke).padding(.leading, 16)
            infoRow(label: "Build", value: Self.buildNumber)
            Divider().background(ColorTheme.stroke).padding(.leading, 16)
            Link(destination: URL(string: Constants.Links.repository)!) {
                HStack {
                    Image(systemName: "link").foregroundStyle(ColorTheme.secondaryAccent).frame(width: 24)
                    Text("View on GitHub").foregroundStyle(ColorTheme.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right").foregroundStyle(ColorTheme.textSecondary)
                }
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            Text("Libraries used: Kingfisher, StarryNight")
                .font(.caption2)
                .foregroundStyle(ColorTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .glassCardSection()
    }

    // MARK: - Building blocks

    private func sectionHeader(_ text: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(ColorTheme.secondaryAccent)
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(ColorTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private func iconBadge(_ icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.18)).frame(width: 32, height: 32)
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(color)
        }
    }

    private func toggleRow(icon: String, iconColor: Color, title: String, subtitle: String, isOn: Binding<Bool>, disabled: Bool = false) -> some View {
        HStack(spacing: 12) {
            iconBadge(icon, color: iconColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold()).foregroundStyle(ColorTheme.textPrimary)
                Text(subtitle).font(.caption2).foregroundStyle(ColorTheme.textSecondary)
            }
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(ColorTheme.primaryAccent).disabled(disabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .opacity(disabled ? 0.5 : 1)
    }

    private func pickerRow<T: Hashable, Content: View>(icon: String, iconColor: Color, title: String, selection: Binding<T>, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            iconBadge(icon, color: iconColor)
            Text(title).font(.subheadline.bold()).foregroundStyle(ColorTheme.textPrimary)
            Spacer()
            Picker("", selection: selection, content: content)
                .pickerStyle(.menu)
                .tint(ColorTheme.secondaryAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func actionRow(icon: String, iconColor: Color, title: String, subtitle: String, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconBadge(icon, color: iconColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(destructive ? ColorTheme.error : ColorTheme.textPrimary)
                    Text(subtitle).font(.caption2).foregroundStyle(ColorTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(ColorTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(ColorTheme.textPrimary)
            Spacer()
            Text(value).foregroundStyle(ColorTheme.textSecondary).font(.subheadline.monospacedDigit())
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    private func applyNotification(_ category: NotificationCategory, _ enabled: Bool) {
        Task { @MainActor in
            guard await NotificationManager.shared.apply(category, enabled: enabled) == false else { return }
            // Permission refused - put the switch back so it reflects reality.
            switch category {
            case .iss: settings.notifyISS = false
            case .moon: settings.notifyMoon = false
            case .events: settings.notifyEvents = false
            }
            permissionDenied = true
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func clearAll() {
        for obs in observations { modelContext.delete(obs) }
        for achievement in achievements { modelContext.delete(achievement) }
        try? modelContext.save()
    }

    private func exportCSV() {
        guard !observations.isEmpty else {
            exportFailed = true
            return
        }

        let stamp = ISO8601DateFormatter()
        stamp.formatOptions = [.withInternetDateTime]

        let header = "Title,ObjectType,Date,Latitude,Longitude,Location,Notes\n"
        let rows = observations.map { o in
            [o.title, o.objectType.rawValue, stamp.string(from: o.timestamp),
             String(o.latitude), String(o.longitude), o.locationName, o.notes]
                .map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }
                .joined(separator: ",")
        }.joined(separator: "\n")

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("stargazer_export.csv")
        do {
            try (header + rows).write(to: url, atomically: true, encoding: .utf8)
            exportFile = ExportFile(url: url)
        } catch {
            exportFailed = true
        }
    }
}

/// Wraps the temp-file URL so `.sheet(item:)` can drive the share sheet.
private struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

private extension View {
    func glassCardSection() -> some View {
        self.glassCard(cornerRadius: 18, tint: ColorTheme.secondaryAccent.opacity(0.6))
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [StarObservation.self, Achievement.self], inMemory: true)
        .preferredColorScheme(.dark)
}
