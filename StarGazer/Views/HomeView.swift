import SwiftUI
import SwiftData
import MapKit

struct HomeView: View {
    @State private var vm = HomeViewModel()
    @Bindable private var settings = SettingsManager.shared
    @Query(sort: \StarObservation.timestamp, order: .reverse) private var observations: [StarObservation]

    @State private var cardsAppeared = false
    @State private var heroAppeared = false
    @State private var issGlowPulse = false
    @State private var showEventsSheet = false
    @State private var showStatsSheet = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Spacer().frame(height: 120)

                        issHeroCard
                            .opacity(heroAppeared ? 1 : 0)
                            .offset(y: heroAppeared ? 0 : 30)
                            .animation(.spring(response: 0.7, dampingFraction: 0.8), value: heroAppeared)

                        twoColumnRow
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 40)
                            .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1), value: cardsAppeared)

                        nextPassCard
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 50)
                            .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2), value: cardsAppeared)

                        recentObservationsRow
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 60)
                            .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.3), value: cardsAppeared)

                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                }
                .refreshable { await vm.loadAll() }

                floatingHeader
                    .ignoresSafeArea(edges: .top)
            }
            .ignoresSafeArea(edges: .top)
            // HomeView draws its own floating header; the empty system bar would
            // otherwise sit on top of it and hide the calendar/stats buttons.
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            await vm.loadAll()
            AppLaunchState.shared.isHomeReady = true
            vm.startRefresh()
            heroAppeared = true
            cardsAppeared = true
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                issGlowPulse = true
            }
        }
        .onDisappear { vm.cancelRefresh() }
    }

    // MARK: - Floating header

    private var floatingHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.secondaryAccent.opacity(0.85))
                    .textCase(.uppercase)
                    .tracking(1.5)
                Text(settings.username)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(ColorTheme.textPrimary)
            }
            Spacer()
            HStack(spacing: 10) {
                headerButton(icon: "calendar") { showEventsSheet = true }
                headerButton(icon: "chart.bar.fill") { showStatsSheet = true }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 58)
        .padding(.bottom, 10)
        .sheet(isPresented: $showEventsSheet) { NavigationStack { EventsCalendarView() } }
        .sheet(isPresented: $showStatsSheet) { NavigationStack { StatisticsView() } }
    }

    private func headerButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ColorTheme.secondaryAccent)
                .frame(width: 34, height: 34)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().strokeBorder(ColorTheme.secondaryAccent.opacity(0.25), lineWidth: 1))
        }
    }

    // MARK: - ISS Hero card

    private var issHeroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                issMapLayer
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                // Live badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .shadow(color: .green, radius: issGlowPulse ? 6 : 2)
                        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: issGlowPulse)
                    Text("LIVE  •  ISS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.55))
                .clipShape(Capsule())
                .padding(12)
            }

            issStatsBar
        }
        .glassCard(cornerRadius: 20, tint: ColorTheme.secondaryAccent)
        .shadow(color: ColorTheme.secondaryAccent.opacity(0.12), radius: 18, y: 6)
    }

    private var issMapLayer: some View {
        Group {
            if let pos = vm.issPosition {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: pos.latitude, longitude: pos.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 110, longitudeDelta: 160)
                ))) {
                    Annotation("ISS", coordinate: CLLocationCoordinate2D(latitude: pos.latitude, longitude: pos.longitude)) {
                        issMapMarker
                    }
                }
                .mapStyle(settings.mapStyle.mapStyle())
                .allowsHitTesting(false)
            } else {
                ZStack {
                    ColorTheme.backgroundDeep
                    VStack(spacing: 12) {
                        ISSIconView(size: 56, glow: false).opacity(0.5)
                        ProgressView().tint(ColorTheme.secondaryAccent)
                    }
                }
            }
        }
    }

    private var issMapMarker: some View {
        ISSIconView(size: issGlowPulse ? 68 : 60)
            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: issGlowPulse)
    }

    private var issStatsBar: some View {
        HStack(spacing: 0) {
            if let pos = vm.issPosition {
                statCell(label: "LAT", value: String(format: "%.2f°", pos.latitude))
                barDivider
                statCell(label: "LON", value: String(format: "%.2f°", pos.longitude))
                barDivider
                statCell(label: "ALT", value: settings.units.distance(kilometres: pos.altitude))
                barDivider
                statCell(label: "VEL", value: settings.units.speed(kilometresPerHour: pos.velocity))
            } else {
                HStack { ProgressView().tint(ColorTheme.secondaryAccent) }.frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
    }

    private var barDivider: some View {
        Rectangle()
            .fill(ColorTheme.textSecondary.opacity(0.15))
            .frame(width: 1, height: 28)
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(ColorTheme.textSecondary)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(ColorTheme.secondaryAccent)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Moon + Weather row

    private var twoColumnRow: some View {
        HStack(spacing: 12) {
            moonSunCard
            weatherCard
        }
        .frame(height: 196)
    }

    private var moonSunCard: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Sky", systemImage: "moon.stars.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ColorTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            Spacer(minLength: 6)

            if let moon = vm.moon {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 4)
                        .frame(width: 56, height: 56)
                    Circle()
                        .trim(from: 0, to: moon.illuminationPercent / 100)
                        .stroke(
                            LinearGradient(
                                colors: [ColorTheme.secondaryAccent, .white],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1.2), value: moon.illuminationPercent)
                    if CelestialIconCache.image(for: "moon") != nil {
                        CelestialIcon(bodyName: "moon", size: 40)
                    } else {
                        Text(moon.emoji).font(.system(size: 22))
                    }
                }

                Text(moon.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ColorTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.top, 8)
                Text("\(Int(moon.illuminationPercent))% illuminated")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(ColorTheme.textSecondary)
                    .padding(.top, 2)
            }

            Spacer(minLength: 8)

            if let sun = vm.sun {
                HStack(spacing: 6) {
                    Image(systemName: "sunrise.fill").foregroundStyle(.orange)
                    Text(timeFormat(sun.sunrise))
                    Spacer()
                    Image(systemName: "sunset.fill").foregroundStyle(.orange.opacity(0.75))
                    Text(timeFormat(sun.sunset))
                }
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(ColorTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassCard(cornerRadius: 20, tint: ColorTheme.secondaryAccent)
        .shadow(color: ColorTheme.secondaryAccent.opacity(0.08), radius: 12)
    }

    private var weatherCard: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Conditions", systemImage: "cloud.moon.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ColorTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            Spacer(minLength: 4)

            if let w = vm.weather {
                Image(systemName: w.conditionIcon)
                    .font(.system(size: 32))
                    .foregroundStyle(w.isGoodForObserving ? ColorTheme.success : ColorTheme.warning)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
                    .frame(height: 38)

                Text(settings.units.temperature(celsius: w.temperatureC))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(ColorTheme.textPrimary)
                    .padding(.top, 4)

                HStack(spacing: 4) {
                    let quality = max(0.0, min(1.0, (100.0 - w.cloudCoverPercent) / 100.0))
                    ForEach(0..<5, id: \.self) { i in
                        Capsule()
                            .fill(Double(i) < quality * 5 ? ColorTheme.success : Color.white.opacity(0.12))
                            .frame(width: 14, height: 4)
                    }
                }
                .padding(.top, 8)
            } else {
                Spacer()
                ProgressView().tint(ColorTheme.secondaryAccent)
                Spacer()
            }

            Spacer(minLength: 8)

            if let w = vm.weather {
                Text(w.isGoodForObserving ? "Good conditions ✓" : "Poor conditions")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(w.isGoodForObserving ? ColorTheme.success : ColorTheme.warning)
                    .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassCard(cornerRadius: 20, tint: ColorTheme.success)
        .shadow(color: ColorTheme.success.opacity(0.08), radius: 12)
    }

    // MARK: - Next pass countdown

    private var nextPassCard: some View {
        HStack(spacing: 16) {
            ISSIconView(size: 60, glow: false)

            VStack(alignment: .leading, spacing: 4) {
                Text("NEXT ISS PASS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.textSecondary)

                if let pass = vm.nextPass {
                    TimelineView(.periodic(from: Date(), by: 1)) { _ in
                        Text(countdownString(to: pass.startTime))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.secondaryAccent)
                            .contentTransition(.numericText())
                    }
                    HStack(spacing: 10) {
                        Label("\(pass.startDirection) → \(pass.endDirection)", systemImage: "arrow.right")
                        Label("Max \(Int(pass.maxAltitudeDeg))°", systemImage: "arrow.up")
                    }
                    .font(.caption2)
                    .foregroundStyle(ColorTheme.textSecondary)
                } else {
                    Text("Calculating…")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(ColorTheme.textSecondary)
                }
            }

            Spacer()

            NavigationLink(destination: ISSPassesView()) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(ColorTheme.primaryAccent.opacity(0.7))
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 20, tint: ColorTheme.primaryAccent)
        .shadow(color: ColorTheme.primaryAccent.opacity(0.2), radius: 14, y: 4)
    }

    // MARK: - Recent observations strip

    private var recentObservationsRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("OBSERVATIONS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.textSecondary)
                Spacer()
                NavigationLink("All →", destination: ObservationLogView())
                    .font(.caption.bold())
                    .foregroundStyle(ColorTheme.secondaryAccent)
            }

            if observations.isEmpty {
                emptyObservations
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(observations.prefix(5))) { obs in
                            NavigationLink(destination: ObservationDetailView(observation: obs)) {
                                miniObsCard(obs)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func miniObsCard(_ obs: StarObservation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                if let data = obs.photoData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [obs.objectType.color.opacity(0.5), ColorTheme.backgroundDeep],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    Image(systemName: obs.objectType.icon)
                        .font(.system(size: 26))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .frame(width: 108, height: 78)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(obs.objectType.color.opacity(0.4), lineWidth: 1)
            )

            Text(obs.title)
                .font(.caption.bold())
                .foregroundStyle(ColorTheme.textPrimary)
                .lineLimit(1)
            Text(obs.timestamp.formattedDay())
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(ColorTheme.textSecondary)
        }
        .frame(width: 108)
    }

    private var emptyObservations: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.title)
                .foregroundStyle(ColorTheme.primaryAccent)
            VStack(alignment: .leading, spacing: 2) {
                Text("No observations")
                    .font(.subheadline.bold())
                    .foregroundStyle(ColorTheme.textPrimary)
                Text("Go to Log to start.")
                    .font(.caption)
                    .foregroundStyle(ColorTheme.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 16, tint: ColorTheme.primaryAccent)
    }

    // MARK: - Helpers

    private func timeFormat(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: d)
    }

    private func countdownString(to date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        if interval <= 0 { return "NOW" }
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let s = Int(interval) % 60
        if h > 0 { return String(format: "%02d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [StarObservation.self, Achievement.self], inMemory: true)
        .preferredColorScheme(.dark)
}
