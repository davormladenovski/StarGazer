import Foundation

enum Constants {
    enum API {
        static let issBase = "https://api.wheretheiss.at/v1"
        static let sunriseSunset = "https://api.sunrise-sunset.org/json"
        static let openMeteo = "https://api.open-meteo.com/v1/forecast"
        static let issNoradID = 25544
    }

    enum Refresh {
        static let issLiveSeconds: TimeInterval = 5
        static let issDashboardSeconds: TimeInterval = 60
        static let weatherCacheSeconds: TimeInterval = 30 * 60
        static let sunCacheSeconds: TimeInterval = 24 * 60 * 60
    }

    enum Links {
        static let repository = "https://github.com/davormladenovski/StarGazer"
    }

    enum Storage {
        static let username = "stargazer.username"
        static let faceIDEnabled = "stargazer.faceID.enabled"
        static let notifyISS = "stargazer.notify.iss"
        static let notifyMoon = "stargazer.notify.moon"
        static let notifyEvents = "stargazer.notify.events"
        static let units = "stargazer.units"
        static let theme = "stargazer.theme"
        static let mapStyle = "stargazer.mapStyle"
    }
}
