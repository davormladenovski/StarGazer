import SwiftUI
import SwiftData

struct ObservationLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StarObservation.timestamp, order: .reverse) private var observations: [StarObservation]

    @State private var search: String = ""
    @State private var filter: ObjectType?
    @State private var showNew = false

    private var filtered: [StarObservation] {
        observations.filter { o in
            (filter == nil || o.objectType == filter) &&
            (search.isEmpty
                || o.title.localizedCaseInsensitiveContains(search)
                || o.locationName.localizedCaseInsensitiveContains(search)
                || o.notes.localizedCaseInsensitiveContains(search))
        }
    }

    private var uniqueLocations: Int {
        Set(observations.map { $0.locationName }).count
    }

    private var spanDays: Int {
        guard let oldest = observations.last?.timestamp else { return 0 }
        return max(1, Calendar.current.dateComponents([.day], from: oldest, to: Date()).day ?? 1)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    filterChips
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                    if !observations.isEmpty {
                        statsBar
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }

                    if filtered.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filtered) { obs in
                                    NavigationLink {
                                        ObservationDetailView(observation: obs)
                                    } label: {
                                        ObservationCard(observation: obs)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 80)
                        }
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showNew = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.bold())
                                .frame(width: 60, height: 60)
                                .background(
                                    LinearGradient(
                                        colors: [ColorTheme.secondaryAccent, ColorTheme.primaryAccent],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundStyle(.black)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                                .shadow(color: ColorTheme.primaryAccent.opacity(0.55), radius: 16, y: 6)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Log")
            .searchable(text: $search, prompt: "Search")
            .toolbarBackground(.hidden, for: .navigationBar)
            .themedToolbar()
            .sheet(isPresented: $showNew) {
                NewObservationView()
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: "All", systemImage: "circle.grid.2x2", active: filter == nil) {
                    filter = nil
                }
                ForEach(ObjectType.allCases) { t in
                    chip(label: t.rawValue, systemImage: t.icon, active: filter == t) {
                        filter = (filter == t) ? nil : t
                    }
                }
            }
        }
    }

    private func chip(label: String, systemImage: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(label)
            }
            .pill(active: active)
        }
    }

    private var statsBar: some View {
        HStack(spacing: 0) {
            statPill(value: "\(observations.count)", label: "observations", color: ColorTheme.secondaryAccent)
            divider
            statPill(value: "\(uniqueLocations)", label: "locations", color: .cyan)
            divider
            statPill(value: "\(spanDays)", label: "days", color: ColorTheme.primaryAccent)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .glassCard(cornerRadius: 14, tint: ColorTheme.secondaryAccent)
    }

    private var divider: some View {
        Rectangle().fill(ColorTheme.stroke).frame(width: 1, height: 26)
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(color)
            Text(label).font(.system(size: 9, design: .monospaced)).foregroundStyle(ColorTheme.textSecondary).textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [ColorTheme.secondaryAccent.opacity(0.25), .clear],
                                       center: .center, startRadius: 0, endRadius: 110)
                    )
                    .frame(width: 220, height: 220)
                Image(systemName: "telescope")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(
                        LinearGradient(colors: [ColorTheme.secondaryAccent, .white],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: ColorTheme.secondaryAccent.opacity(0.5), radius: 18)
            }

            VStack(spacing: 6) {
                Text("No observations yet")
                    .font(.title3.bold())
                    .foregroundStyle(ColorTheme.textPrimary)
                Text("Tap + to start tracking the sky.")
                    .font(.subheadline)
                    .foregroundStyle(ColorTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Spacer()
        }
    }
}

#Preview {
    ObservationLogView()
        .modelContainer(for: [StarObservation.self, Achievement.self], inMemory: true)
        .preferredColorScheme(.dark)
}
