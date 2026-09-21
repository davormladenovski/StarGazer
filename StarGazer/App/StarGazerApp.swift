import SwiftUI
import SwiftData

@main
struct StarGazerApp: App {
    @State private var isUnlocked = false
    @State private var splashFinished = false
    private let settings = SettingsManager.shared

    var container: ModelContainer = {
        let schema = Schema([StarObservation.self, Achievement.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer failed: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isUnlocked {
                    RootTabView()
                        .transition(.opacity)
                } else {
                    LockView(isUnlocked: $isUnlocked)
                        .transition(.opacity)
                }

                if !splashFinished {
                    SplashScreenView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            splashFinished = true
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .preferredColorScheme(settings.theme.colorScheme)   // nil == follow the system (Automatic)
        }
        .modelContainer(container)
    }
}
