import SwiftUI

struct EventDetailView: View {
    let event: AstronomicalEvent

    @State private var notified = false
    @State private var showAddObservation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                titleBlock
                infoGrid
                description
                actions
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(AppBackground())
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .themedToolbar()
        .fullScreenCover(isPresented: $showAddObservation) {
            NavigationStack {
                NewObservationView(prefilledTitle: event.name, prefilledType: prefilledType, detectedBody: event.name)
            }
        }
    }

    private var hero: some View {
        ZStack {
            LinearGradient(
                colors: [event.type.color.opacity(0.6), ColorTheme.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: event.type.icon)
                .font(.system(size: 80))
                .foregroundStyle(.white)
                .shadow(color: event.type.color, radius: 30)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.name)
                .font(.title2.bold())
                .foregroundStyle(ColorTheme.textPrimary)
            HStack(spacing: 6) {
                Image(systemName: event.type.icon)
                Text(event.type.label)
            }
            .font(.subheadline.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(event.type.color.opacity(0.2))
            .foregroundStyle(event.type.color)
            .clipShape(Capsule())
        }
    }

    private var infoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            infoCard(label: "When", value: dateLine, icon: "clock.fill")
            infoCard(label: "Where", value: event.directionHint, icon: "location.north.fill")
            infoCard(label: "What to expect", value: expectation, icon: "eye.fill")
        }
    }

    private func infoCard(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon).font(.caption2).foregroundStyle(ColorTheme.textSecondary)
            Text(value).font(.caption.bold()).foregroundStyle(ColorTheme.textPrimary).lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .glassCard(cornerRadius: 12, tint: event.type.color)
    }

    private var description: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description").font(.headline).foregroundStyle(ColorTheme.textPrimary)
            Text(event.description).foregroundStyle(ColorTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard(cornerRadius: 16)
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    await NotificationManager.shared.scheduleEvent(name: event.name, at: event.date)
                    notified = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } label: {
                Label(notified ? "Reminder set" : "Set reminder", systemImage: notified ? "bell.fill" : "bell")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(notified ? ColorTheme.success : ColorTheme.primaryAccent)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(notified)

            Button {
                showAddObservation = true
            } label: {
                Label("Add to log", systemImage: "book.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(ColorTheme.surface)
                    .foregroundStyle(ColorTheme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTheme.primaryAccent.opacity(0.5)))
            }
        }
    }

    private var dateLine: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy\nHH:mm"
        return f.string(from: event.date)
    }

    private var expectation: String {
        switch event.type {
        case .meteorShower: return "Many meteors per hour"
        case .fullMoon: return "Fully illuminated surface"
        case .newMoon: return "Dark sky, ideal for deep-sky"
        case .lunarEclipse, .solarEclipse: return "Visible color/shape change"
        case .conjunction: return "Two objects very close"
        case .issPass: return "A point of light in the sky"
        case .other: return "Seasonal event"
        }
    }

    private var prefilledType: ObjectType {
        switch event.type {
        case .meteorShower: return .meteor
        case .fullMoon, .newMoon, .lunarEclipse: return .moon
        case .issPass: return .iss
        default: return .other
        }
    }
}

#Preview {
    NavigationStack {
        EventDetailView(event: AstronomicalEvent(
            id: "preview", name: "Perseids", type: .meteorShower,
            date: Date(), description: "Test description.",
            directionHint: "Northeast"
        ))
    }
    .preferredColorScheme(.dark)
}
