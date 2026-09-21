import SwiftUI

struct RootTabView: View {
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            NavigationStack {
                ISSMapView()
                    .navigationTitle("ISS Map")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.hidden, for: .navigationBar)
                    .themedToolbar()
            }
            .tabItem { Label("Map", systemImage: "globe") }
            .tag(1)

            SkyCompassView()
                .tabItem { Label("Compass", systemImage: "location.north.line.fill") }
                .tag(2)

            ObservationLogView()
                .tabItem { Label("Log", systemImage: "book.fill") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .tint(ColorTheme.secondaryAccent)
        .task { await NotificationManager.shared.refreshScheduledWork() }
    }
}

