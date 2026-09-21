import SwiftUI

struct ObservationCard: View {
    let observation: StarObservation

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(observation.title)
                    .font(.headline)
                    .foregroundStyle(ColorTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: observation.objectType.icon)
                        .font(.caption)
                    Text(observation.objectType.rawValue)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(observation.objectType.color.opacity(0.2))
                .foregroundStyle(observation.objectType.color)
                .clipShape(Capsule())

                Text("\(observation.locationName) • \(observation.timestamp.formattedDay())")
                    .font(.caption)
                    .foregroundStyle(ColorTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(ColorTheme.textSecondary)
        }
        .padding(12)
        .glassCard(cornerRadius: 16, tint: observation.objectType.color)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = observation.photoData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [observation.objectType.color.opacity(0.35), ColorTheme.surface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: observation.objectType.icon)
                    .font(.title2)
                    .foregroundStyle(observation.objectType.color)
            }
        }
    }
}
