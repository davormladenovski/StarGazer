import SwiftUI
import SwiftData
import MapKit

struct ObservationDetailView: View {
    let observation: StarObservation

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var cameraPosition: MapCameraPosition

    init(observation: StarObservation) {
        self.observation = observation
        let coord = CLLocationCoordinate2D(latitude: observation.latitude, longitude: observation.longitude)
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroImage
                titleBlock
                metadataGrid
                miniMap
                if !observation.notes.isEmpty { notesBlock }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(AppBackground())
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .themedToolbar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(item: shareText) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog("Delete this observation?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(observation)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var shareText: String {
        "\(observation.title) — \(observation.objectType.rawValue) from \(observation.locationName) on \(observation.timestamp.formattedShort())"
    }

    @ViewBuilder
    private var heroImage: some View {
        if let data = observation.photoData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        } else {
            ZStack {
                LinearGradient(
                    colors: [observation.objectType.color.opacity(0.5), ColorTheme.surface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: observation.objectType.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(observation.title)
                .font(.largeTitle.bold())
                .foregroundStyle(ColorTheme.textPrimary)

            HStack(spacing: 6) {
                Image(systemName: observation.objectType.icon)
                Text(observation.objectType.rawValue)
            }
            .font(.subheadline.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(observation.objectType.color.opacity(0.2))
            .foregroundStyle(observation.objectType.color)
            .clipShape(Capsule())
        }
    }

    private var metadataGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metaCard("Location", value: observation.locationName, icon: "mappin.and.ellipse")
            metaCard("Time", value: observation.timestamp.formattedShort(), icon: "clock.fill")
            metaCard("Weather", value: observation.weatherCondition ?? "—", icon: "cloud.fill")
            metaCard("Moon phase", value: observation.moonPhase ?? "—", icon: "moon.fill")
        }
    }

    private func metaCard(_ label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.caption)
            .foregroundStyle(ColorTheme.textSecondary)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(ColorTheme.textPrimary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .glassCard(cornerRadius: 14)
    }

    private var miniMap: some View {
        Map(position: $cameraPosition) {
            Annotation(
                observation.title,
                coordinate: CLLocationCoordinate2D(latitude: observation.latitude, longitude: observation.longitude)
            ) {
                ZStack {
                    Circle().fill(observation.objectType.color).frame(width: 28, height: 28)
                    Image(systemName: observation.objectType.icon)
                        .font(.caption.bold())
                        .foregroundStyle(.black)
                }
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .allowsHitTesting(false)
    }

    private var notesBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(ColorTheme.textPrimary)
            Text(observation.notes)
                .foregroundStyle(ColorTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard(cornerRadius: 16)
    }
}
