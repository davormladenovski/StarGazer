# StarGazer — Implementation Mapping

This document maps each project requirement to its implementing file(s). It will be expanded as later phases are implemented.

## Phase 1 — Foundation (Complete)

| Requirement | File | Line(s) | Notes |
|---|---|---|---|
| App entry + SwiftData ModelContainer | StarGazer/App/StarGazerApp.swift | 1–35 | @main, holds Observation + Achievement schema |
| Color theme (dark, navy + gold) | StarGazer/Utilities/ColorTheme.swift | 1–18 | All theme colors centralized |
| Constants (API URLs, refresh, keys) | StarGazer/Utilities/Constants.swift | 1–32 | |
| Date/Double/View extensions | StarGazer/Utilities/Extensions.swift | 1–46 | Greeting helper, julianDay, deg/rad |
| ObjectType enum | StarGazer/Models/ObjectType.swift | 1–36 | Macedonian labels + SF Symbols |
| SwiftData @Model — Observation | StarGazer/Models/Observation.swift | 1–53 | All required fields |
| SwiftData @Model — Achievement | StarGazer/Models/Achievement.swift | 1–43 | Seed defaults included |
| UserDefaults wrapper (SettingsManager) | StarGazer/Services/System/SettingsManager.swift | 1–85 | @Observable singleton |
| Second sensor — Face ID (LocalAuthentication) | StarGazer/Services/Hardware/BiometricService.swift | 1–55 | Async/await wrapper |
| Custom animated view | StarGazer/Views/Components/AnimatedStarFieldView.swift | 1–120 | TimelineView + Canvas, twinkle + meteors |
| Lock screen | StarGazer/Views/LockView.swift | 1–95 | Uses BiometricService + AnimatedStarFieldView |
| Tab navigation skeleton | StarGazer/Views/RootTabView.swift | 1–95 | 5 tabs; placeholders for phases 2–4 |
| Settings screen | StarGazer/Views/SettingsView.swift | 1–110 | Full preferences form, CSV export, clear data |

## Phase 2 — Core data flow (Complete)

| Requirement | File | Line(s) | Notes |
|---|---|---|---|
| CoreLocation wrapper | StarGazer/Services/Hardware/LocationService.swift | 1–105 | Async one-shot + continuous + reverse geocode |
| Camera (AVFoundation) | StarGazer/Services/Hardware/CameraService.swift | 1–135 | AVCaptureSession + photo capture + preview layer |
| Camera capture UI | StarGazer/Views/Components/CameraCaptureView.swift | 1–70 | Live preview + shutter button + haptics |
| New observation screen | StarGazer/Views/NewObservationView.swift | 1–165 | Camera + PhotosPicker + auto-detected metadata |
| Observation card | StarGazer/Views/Components/ObservationCard.swift | 1–60 | Thumbnail + type pill + location/date |
| Observation log + Kingfisher | StarGazer/Views/ObservationLogView.swift | 1–170 | Search, filter chips, stats bar, FAB. `#if canImport(Kingfisher)` for remote hero image. |
| Observation detail | StarGazer/Views/ObservationDetailView.swift | 1–170 | Hero photo, metadata grid, MapKit mini-map, share/delete |

## Phase 3 — APIs (Complete)

| Requirement | File | Line(s) | Notes |
|---|---|---|---|
| API models + error enum | StarGazer/Models/APIModels.swift | 1–115 | ISSPosition, SunData, WeatherSnapshot, WeatherCode |
| External API #3 (Open-Meteo) | StarGazer/Services/API/WeatherService.swift | 1–60 | 30 min cache, falls back to cache when offline |
| External API #2 (Sunrise-Sunset) | StarGazer/Services/API/SunriseSunsetService.swift | 1–70 | 1 day cache per location |
| External API #1 (Where The ISS At?) | StarGazer/Services/API/ISSService.swift | 1–110 | Live position, trajectory, simulated passes |
| Moon phase (used by HomeView) | StarGazer/Services/Local/MoonPhaseCalculator.swift | 1–80 | Synodic-period calc, ±0.5d accuracy |
| Mock notifications (UNUserNotificationCenter) | StarGazer/Services/System/NotificationManager.swift | 1–60 | ISS passes, events, observation reminders |
| HomeView ViewModel | StarGazer/ViewModels/HomeViewModel.swift | 1–55 | Parallel async loads, 60s refresh |
| HomeView dashboard | StarGazer/Views/HomeView.swift | 1–230 | Hero ISS card + 4 grid cards |
| ISS map ViewModel | StarGazer/ViewModels/ISSMapViewModel.swift | 1–50 | 5s live refresh, trajectory polyline |
| ISS live map | StarGazer/Views/ISSMapView.swift | 1–145 | Hybrid MapKit, pulsing ISS marker, user pin, bottom pass sheet |
| ISS passes ViewModel | StarGazer/ViewModels/ISSPassesViewModel.swift | 1–45 | All / visible / week filter |
| ISS passes | StarGazer/Views/ISSPassesView.swift | 1–115 | Pass cards with reminder button |

## Phase 4 — Advanced (Complete)

| Requirement | File | Line(s) | Notes |
|---|---|---|---|
| Moon phase calculator | StarGazer/Services/Local/MoonPhaseCalculator.swift | 1–80 | Done in Phase 3 |
| Celestial math (RA/Dec → Az/Alt) | StarGazer/Services/Local/CelestialMath.swift | 1–80 | LST + horizontal conversion + great-circle separation |
| Celestial body model | StarGazer/Models/CelestialBody.swift | 1–40 | |
| Star catalog | StarGazer/Resources/yale_bright_star_catalog.csv + StarGazer/Services/Local/StarCatalogService.swift | 1–95 | 50+ brightest stars; FOV filter |
| Planet positions | StarGazer/Services/Local/PlanetCalculator.swift | 1–145 | Keplerian elements, ~1° accuracy |
| Second sensor (Motion) | StarGazer/Services/Hardware/MotionService.swift | 1–80 | CoreMotion attitude + CLHeading magnetometer |
| Sky compass ViewModel | StarGazer/ViewModels/SkyCompassViewModel.swift | 1–110 | Star + planet + moon, FOV filtered |
| Sky compass screen | StarGazer/Views/SkyCompassView.swift | 1–270 | Live camera, compass rose, celestial labels overlay, save to journal |

## Phase 5 — Polish (Complete)

| Requirement | File | Line(s) | Notes |
|---|---|---|---|
| Events data file | StarGazer/Resources/astronomical_events_2026.json | — | 18 events: moons, meteor showers, eclipses, solstices |
| Events model + service | StarGazer/Services/Local/AstronomicalEventsService.swift | 1–110 | Type/color/icon mapping, month/day queries |
| Events ViewModel | StarGazer/ViewModels/EventsViewModel.swift | 1–45 | Month navigation, notify toggles |
| Events calendar | StarGazer/Views/EventsCalendarView.swift | 1–175 | Custom month grid with event dots + legend + list |
| Event detail | StarGazer/Views/EventDetailView.swift | 1–155 | Hero, info grid, description, reminder, add-to-log |
| Statistics ViewModel | StarGazer/ViewModels/StatisticsViewModel.swift | 1–95 | Monthly counts, streaks, favorites, calendar extension |
| Statistics + Swift Charts | StarGazer/Views/StatisticsView.swift | 1–215 | Profile, achievements, BarMark chart, locations map, top stats |
| Notifications | StarGazer/Services/System/NotificationManager.swift | 1–60 | Done in Phase 3, used by passes/events/reminders |
| HomeView toolbar nav | StarGazer/Views/HomeView.swift | (toolbar) | NavigationLinks to events + stats |

## Third-party libraries (planned, added in later phases)

| Library | Purpose | Where |
|---|---|---|
| Kingfisher | Async image loading/caching | ObservationLogView (Phase 2) |
| StarryNight | Star catalog (or CSV fallback) | StarCatalogService (Phase 4) |

## Required permissions (Info.plist)

Add the following keys when creating the Xcode project:
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSLocationWhenInUseUsageDescription`
- `NSMotionUsageDescription`
- `NSFaceIDUsageDescription`
