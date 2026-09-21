import Foundation
import SwiftData

@Model
final class StarObservation {
    var id: UUID
    var title: String
    var objectTypeRaw: String
    var photoData: Data?
    var latitude: Double
    var longitude: Double
    var locationName: String
    var timestamp: Date
    var notes: String
    var weatherCondition: String?
    var moonPhase: String?
    var temperature: Double?
    var detectedCelestialBody: String?

    var objectType: ObjectType {
        get { ObjectType(rawValue: objectTypeRaw) ?? .other }
        set { objectTypeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        objectType: ObjectType,
        photoData: Data? = nil,
        latitude: Double,
        longitude: Double,
        locationName: String,
        timestamp: Date = Date(),
        notes: String = "",
        weatherCondition: String? = nil,
        moonPhase: String? = nil,
        temperature: Double? = nil,
        detectedCelestialBody: String? = nil
    ) {
        self.id = id
        self.title = title
        self.objectTypeRaw = objectType.rawValue
        self.photoData = photoData
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.timestamp = timestamp
        self.notes = notes
        self.weatherCondition = weatherCondition
        self.moonPhase = moonPhase
        self.temperature = temperature
        self.detectedCelestialBody = detectedCelestialBody
    }
}
