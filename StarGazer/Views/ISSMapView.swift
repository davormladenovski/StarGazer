import SwiftUI
import MapKit

struct ISSMapView: View {
    @Bindable private var settings = SettingsManager.shared
    @State private var vm = ISSMapViewModel()
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 80)
        )
    )
    @State private var pulse: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .top) {
            map
                .ignoresSafeArea(edges: .bottom)
            topInfoBar
            bottomPassSheet
        }
        .task {
            vm.start()
            await vm.loadNextPass()
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = 1.5
            }
        }
        .onDisappear { vm.cancel() }
    }

    private var map: some View {
        Map(position: $cameraPosition) {
            if let pos = vm.position {
                let coord = CLLocationCoordinate2D(latitude: pos.latitude, longitude: pos.longitude)
                Annotation("ISS", coordinate: coord) {
                    ISSIconView(size: 80)
                        .scaleEffect(pulse * 0.6 + 0.7)
                }
            }
            if vm.trajectory.count > 1 {
                MapPolyline(coordinates: vm.trajectory)
                    .stroke(ColorTheme.secondaryAccent.opacity(0.8), lineWidth: 2)
            }
            UserAnnotation()
        }
        .mapStyle(settings.mapStyle.mapStyle(elevation: .realistic))
        .onChange(of: vm.position?.latitude) { _, _ in
            if let pos = vm.position {
                withAnimation(.easeInOut(duration: 0.5)) {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: pos.latitude, longitude: pos.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 80)
                    ))
                }
            }
        }
    }

    private var topInfoBar: some View {
        Group {
            if let pos = vm.position {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ISS").font(.caption).foregroundStyle(ColorTheme.textSecondary)
                        Text(String(format: "%.2f°, %.2f°", pos.latitude, pos.longitude))
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(ColorTheme.textPrimary)
                    }
                    Divider().frame(height: 28).background(.white.opacity(0.3))
                    metric("Altitude", value: settings.units.distance(kilometres: pos.altitude))
                    metric("Speed", value: settings.units.speed(kilometresPerHour: pos.velocity))
                    Spacer()
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }

    private func metric(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(ColorTheme.textSecondary)
            Text(value).font(.caption.bold().monospacedDigit())
                .foregroundStyle(ColorTheme.textPrimary)
        }
    }

    private var bottomPassSheet: some View {
        VStack {
            Spacer()
            HStack {
                ISSIconView(size: 44, glow: false)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next pass").font(.caption).foregroundStyle(ColorTheme.textSecondary)
                    if let p = vm.nextPass {
                        Text("in \(countdown(to: p.startTime)) • \(p.startDirection) → \(p.endDirection)")
                            .font(.subheadline.bold())
                            .foregroundStyle(ColorTheme.textPrimary)
                    } else {
                        Text("Calculating…").font(.subheadline).foregroundStyle(ColorTheme.textSecondary)
                    }
                }
                Spacer()
                NavigationLink {
                    ISSPassesView()
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title)
                        .foregroundStyle(ColorTheme.secondaryAccent)
                }
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }

    private func countdown(to date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        if interval < 0 { return "—" }
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

#Preview {
    NavigationStack { ISSMapView() }
}
