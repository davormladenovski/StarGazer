import SwiftUI
import SwiftData
import PhotosUI
import CoreLocation

struct NewObservationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var objectType: ObjectType = .star
    @State private var notes: String = ""
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var setReminder = false
    @State private var saving = false

    @State private var location: CLLocation?
    @State private var locationName: String = "Loading location…"
    @State private var moonPhaseText: String = "—"
    @State private var weatherText: String = "—"
    @State private var temperature: Double?

    var prefilledTitle: String?
    var prefilledType: ObjectType?
    var prefilledPhoto: Data?
    var detectedBody: String?

    private let locationService = LocationService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        photoSection
                        detailsSection
                        autoSection
                        reminderSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New observation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .themedToolbar()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(ColorTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        save()
                    } label: {
                        Text("Save")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(
                                    title.isEmpty ? ColorTheme.surface : ColorTheme.primaryAccent
                                )
                            )
                            .foregroundStyle(title.isEmpty ? ColorTheme.textSecondary : .black)
                    }
                    .disabled(title.isEmpty || saving)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView { image in
                    self.photoData = image.jpegData(compressionQuality: 0.85)
                }
            }
            .onChange(of: photoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
            .task { await loadAutoDetected() }
            .onAppear { applyPrefill() }
        }
    }

    // MARK: - Sections

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(text: "Photo", icon: "camera.fill")
            ZStack {
                if let data = photoData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 160)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 32))
                                    .foregroundStyle(ColorTheme.textSecondary)
                                Text("Add a photo")
                                    .font(.caption)
                                    .foregroundStyle(ColorTheme.textSecondary)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(ColorTheme.stroke, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                        )
                }
            }

            HStack(spacing: 10) {
                actionButton(label: "Camera", icon: "camera.fill") { showCamera = true }
                PhotosPicker(selection: $photoItem, matching: .images) {
                    actionButtonLabel(label: "Gallery", icon: "photo.on.rectangle")
                }
                if photoData != nil {
                    Button {
                        photoData = nil
                        photoItem = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.bold())
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                            .foregroundStyle(ColorTheme.error)
                    }
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 18, tint: ColorTheme.secondaryAccent)
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(text: "Details", icon: "sparkles")

            VStack(alignment: .leading, spacing: 6) {
                Text("Title").font(.caption).foregroundStyle(ColorTheme.textSecondary)
                TextField("", text: $title, prompt: Text("e.g. Moon over Skopje").foregroundStyle(ColorTheme.textSecondary.opacity(0.6)))
                    .textFieldStyle(.plain)
                    .foregroundStyle(ColorTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(ColorTheme.stroke, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Object type").font(.caption).foregroundStyle(ColorTheme.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ObjectType.allCases) { t in
                            Button {
                                objectType = t
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: t.icon)
                                    Text(t.rawValue)
                                }
                                .pill(active: objectType == t)
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Notes").font(.caption).foregroundStyle(ColorTheme.textSecondary)
                ZStack(alignment: .topLeading) {
                    if notes.isEmpty {
                        Text("Share your impressions, conditions, gear…")
                            .foregroundStyle(ColorTheme.textSecondary.opacity(0.6))
                            .padding(.top, 12)
                            .padding(.leading, 14)
                    }
                    TextEditor(text: $notes)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(ColorTheme.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .frame(minHeight: 110)
                }
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(ColorTheme.stroke, lineWidth: 1))
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 18, tint: objectType.color)
    }

    private var autoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(text: "Auto detected", icon: "wand.and.stars")
            autoRow(icon: "mappin.circle.fill", label: "Location", value: locationName, color: .red)
            autoRow(icon: "clock.fill", label: "Time", value: Date().formattedShort(), color: .blue)
            autoRow(icon: "cloud.fill", label: "Weather", value: weatherText, color: .cyan)
            autoRow(icon: "moon.fill", label: "Moon phase", value: moonPhaseText, color: ColorTheme.secondaryAccent)
            if let detectedBody {
                autoRow(icon: "sparkles", label: "Body", value: detectedBody, color: .purple)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 18, tint: .cyan)
    }

    private func autoRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.18)).frame(width: 30, height: 30)
                Image(systemName: icon).font(.caption).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption2).foregroundStyle(ColorTheme.textSecondary)
                Text(value).font(.subheadline.bold()).foregroundStyle(ColorTheme.textPrimary).lineLimit(2)
            }
            Spacer()
        }
    }

    private var reminderSection: some View {
        HStack {
            ZStack {
                Circle().fill(ColorTheme.primaryAccent.opacity(0.18)).frame(width: 36, height: 36)
                Image(systemName: "bell.fill").foregroundStyle(ColorTheme.primaryAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Reminder").font(.subheadline.bold()).foregroundStyle(ColorTheme.textPrimary)
                Text("Tomorrow night at the same time").font(.caption).foregroundStyle(ColorTheme.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $setReminder).labelsHidden().tint(ColorTheme.primaryAccent)
        }
        .padding(16)
        .glassCard(cornerRadius: 18, tint: ColorTheme.primaryAccent)
    }

    // MARK: - Helpers

    private func actionButton(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            actionButtonLabel(label: label, icon: icon)
        }
    }

    private func actionButtonLabel(label: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(label)
        }
        .font(.caption.bold())
        .foregroundStyle(ColorTheme.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(ColorTheme.stroke, lineWidth: 1))
    }

    private func applyPrefill() {
        if title.isEmpty, let t = prefilledTitle { title = t }
        if let pt = prefilledType { objectType = pt }
        if photoData == nil, let p = prefilledPhoto { photoData = p }
    }

    private func loadAutoDetected() async {
        // Moon phase is location-independent — fill immediately.
        let moon = MoonPhaseCalculator.phase(for: Date())
        moonPhaseText = moon.name

        do {
            let loc = try await locationService.currentLocationOnce()
            location = loc
            locationName = await locationService.reverseGeocode(loc)

            if let w = try? await WeatherService.shared.currentWeather(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude
            ) {
                weatherText = w.conditionLabel
                temperature = w.temperatureC
            }
        } catch {
            locationName = "Location not available"
        }
    }

    private func save() {
        saving = true
        let loc = location
        let obs = StarObservation(
            title: title,
            objectType: objectType,
            photoData: photoData,
            latitude: loc?.coordinate.latitude ?? 0,
            longitude: loc?.coordinate.longitude ?? 0,
            locationName: locationName,
            timestamp: Date(),
            notes: notes,
            weatherCondition: weatherText == "—" ? nil : weatherText,
            moonPhase: moonPhaseText == "—" ? nil : moonPhaseText,
            temperature: temperature,
            detectedCelestialBody: detectedBody
        )
        modelContext.insert(obs)
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }
}

#Preview {
    NewObservationView()
        .modelContainer(for: [StarObservation.self, Achievement.self], inMemory: true)
        .preferredColorScheme(.dark)
}
