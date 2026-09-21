import SwiftUI

struct ISSPassesView: View {
    @State private var vm = ISSPassesViewModel()
    @State private var notifiedIDs: Set<UUID> = []

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                filterBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                if vm.isLoading && vm.passes.isEmpty {
                    Spacer()
                    ProgressView().tint(ColorTheme.secondaryAccent)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(vm.filtered) { pass in
                                passCard(pass)
                            }
                            if vm.filtered.isEmpty {
                                Text("No passes for the selected filter.")
                                    .foregroundStyle(ColorTheme.textSecondary)
                                    .padding(.top, 40)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationTitle("ISS Passes")
        .toolbarBackground(.hidden, for: .navigationBar)
        .themedToolbar()
        .task {
            if vm.passes.isEmpty { await vm.load() }
        }
    }

    @ViewBuilder
    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Upcoming passes over \(vm.locationName)")
                .font(.caption)
                .foregroundStyle(ColorTheme.textSecondary)

            HStack(spacing: 8) {
                ForEach(PassFilter.allCases) { f in
                    Button {
                        vm.filter = f
                    } label: {
                        Text(f.label).pill(active: vm.filter == f)
                    }
                }
                Spacer()
            }
        }
    }

    private func passCard(_ pass: ISSPass) -> some View {
        let f = DateFormatter(); f.dateFormat = "EEE, d MMM • HH:mm"

        return HStack(spacing: 14) {
            VStack(spacing: 2) {
                Image(systemName: pass.visible ? "eye.fill" : "eye.slash.fill")
                    .foregroundStyle(pass.visible ? ColorTheme.secondaryAccent : ColorTheme.textSecondary)
                Text(pass.visible ? "Visible" : "Hidden")
                    .font(.caption2)
                    .foregroundStyle(ColorTheme.textSecondary)
            }
            .frame(width: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(f.string(from: pass.startTime))
                    .font(.subheadline.bold())
                    .foregroundStyle(ColorTheme.textPrimary)
                HStack(spacing: 12) {
                    Label("\(pass.durationMinutes)m", systemImage: "clock")
                    Label("\(pass.startDirection) → \(pass.endDirection)", systemImage: "arrow.up.right")
                    Label("\(Int(pass.maxAltitudeDeg))°", systemImage: "arrow.up")
                }
                .font(.caption)
                .foregroundStyle(ColorTheme.textSecondary)
            }

            Spacer()

            Button {
                Task {
                    await NotificationManager.shared.scheduleISSPass(at: pass.startTime, direction: pass.startDirection)
                    notifiedIDs.insert(pass.id)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } label: {
                Image(systemName: notifiedIDs.contains(pass.id) ? "bell.fill" : "bell")
                    .font(.title3)
                    .foregroundStyle(notifiedIDs.contains(pass.id) ? ColorTheme.secondaryAccent : ColorTheme.textSecondary)
            }
            .disabled(notifiedIDs.contains(pass.id))
        }
        .padding(14)
        .glassCard(cornerRadius: 14, tint: pass.visible ? ColorTheme.secondaryAccent : Color.white.opacity(0.15))
    }
}

#Preview {
    NavigationStack { ISSPassesView() }
        .preferredColorScheme(.dark)
}
