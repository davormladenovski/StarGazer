import SwiftUI
import SwiftData
import Charts
import MapKit

struct StatisticsView: View {
    @Query(sort: \StarObservation.timestamp, order: .reverse) private var observations: [StarObservation]
    @Query private var achievements: [Achievement]
    @Environment(\.modelContext) private var modelContext
    @State private var vm = StatisticsViewModel()
    @Bindable private var settings = SettingsManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                profileHeader
                achievementsRow
                chartCard
                mapCard
                topStats
            }
            .padding()
        }
        .background(AppBackground())
        .navigationTitle("Statistics")
        .toolbarBackground(.hidden, for: .navigationBar)
        .themedToolbar()
        .task { seedAchievementsIfNeeded() }
    }

    // MARK: - Sections

    private var profileHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(ColorTheme.primaryAccent).frame(width: 64, height: 64)
                Image(systemName: "person.fill")
                    .font(.title)
                    .foregroundStyle(.black)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(settings.username).font(.title2.bold()).foregroundStyle(ColorTheme.textPrimary)
                Text("\(observations.count) observations")
                    .font(.caption).foregroundStyle(ColorTheme.textSecondary)
            }
            Spacer()
        }
    }

    private var achievementsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Achievements").font(.caption.bold()).foregroundStyle(ColorTheme.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(achievements) { a in
                        achievementCard(a)
                    }
                }
            }
        }
    }

    private func achievementCard(_ a: Achievement) -> some View {
        let dynamicProgress = computedProgress(for: a)
        let unlocked = dynamicProgress >= a.target
        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(unlocked ? ColorTheme.primaryAccent : ColorTheme.surface)
                    .frame(width: 54, height: 54)
                Image(systemName: a.iconName)
                    .font(.title3)
                    .foregroundStyle(unlocked ? .black : ColorTheme.textSecondary)
            }
            Text(a.name).font(.caption2.bold()).foregroundStyle(ColorTheme.textPrimary)
            Text("\(min(dynamicProgress, a.target))/\(a.target)")
                .font(.system(size: 9))
                .foregroundStyle(ColorTheme.textSecondary)
        }
        .frame(width: 92)
        .padding(8)
        .glassCard(cornerRadius: 14, tint: unlocked ? ColorTheme.primaryAccent : Color.white.opacity(0.2))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Monthly activity").font(.caption.bold()).foregroundStyle(ColorTheme.textSecondary)
            let data = vm.monthlyCounts(from: observations)
            Chart(data) { item in
                BarMark(
                    x: .value("Moon", item.label),
                    y: .value("Observations", item.count)
                )
                .cornerRadius(4)
                .foregroundStyle(LinearGradient(
                    colors: [ColorTheme.primaryAccent, ColorTheme.secondaryAccent],
                    startPoint: .bottom, endPoint: .top
                ))
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                    AxisGridLine().foregroundStyle(ColorTheme.textSecondary.opacity(0.2))
                    AxisValueLabel().foregroundStyle(ColorTheme.textSecondary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(ColorTheme.textSecondary)
                }
            }
            .frame(height: 200)
        }
        .padding(14)
        .glassCard(cornerRadius: 18, tint: ColorTheme.secondaryAccent)
    }

    private var mapCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Observation locations").font(.caption.bold()).foregroundStyle(ColorTheme.textSecondary)
            Map {
                ForEach(observations) { obs in
                    Annotation(obs.title, coordinate: CLLocationCoordinate2D(latitude: obs.latitude, longitude: obs.longitude)) {
                        ZStack {
                            Circle().fill(obs.objectType.color).frame(width: 18, height: 18)
                            Image(systemName: obs.objectType.icon).font(.system(size: 9, weight: .bold)).foregroundStyle(.black)
                        }
                    }
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(14)
        .glassCard(cornerRadius: 18, tint: .cyan)
    }

    private var topStats: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top stats").font(.caption.bold()).foregroundStyle(ColorTheme.textSecondary)
            statRow(
                icon: "star.fill",
                label: "Most observed object",
                value: vm.mostObservedType(observations)?.rawValue ?? "—"
            )
            statRow(
                icon: "mappin.circle.fill",
                label: "Favorite location",
                value: vm.favoriteLocation(observations)?.name ?? "—"
            )
            statRow(
                icon: "moon.stars.fill",
                label: "Nights observed",
                value: "\(vm.nightsObserved(observations))"
            )
            statRow(
                icon: "flame.fill",
                label: "Longest streak",
                value: "\(vm.longestStreak(observations)) days"
            )
        }
        .padding(14)
        .glassCard(cornerRadius: 18, tint: ColorTheme.primaryAccent)
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(ColorTheme.secondaryAccent).frame(width: 24)
            Text(label).foregroundStyle(ColorTheme.textSecondary)
            Spacer()
            Text(value).font(.subheadline.bold()).foregroundStyle(ColorTheme.textPrimary)
        }
        .font(.caption)
    }

    // MARK: - Achievement progress logic

    private func computedProgress(for a: Achievement) -> Int {
        switch a.iconName {
        case "star.fill":
            return observations.isEmpty ? 0 : 1
        case "sparkles":
            return observations.count
        case "airplane":
            return observations.filter { $0.objectType == .iss }.count
        case "moon.stars.fill":
            return Set(observations.compactMap { $0.moonPhase }).count
        case "map.fill":
            return Set(observations.map { $0.locationName }).count
        default:
            return a.progress
        }
    }

    private func seedAchievementsIfNeeded() {
        if achievements.isEmpty {
            for a in Achievement.seedDefaults() {
                modelContext.insert(a)
            }
            try? modelContext.save()
        }
    }
}

#Preview {
    NavigationStack { StatisticsView() }
        .modelContainer(for: [StarObservation.self, Achievement.self], inMemory: true)
        .preferredColorScheme(.dark)
}
