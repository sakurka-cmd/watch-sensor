import Foundation

// MARK: - Модели API-ответов сервера esp32-sensor-monitor

struct SensorLatest: Codable {
    let temperature: Double
    let pressure: Double
    let humidity: Double
    let timestamp: String
}

struct SensorStats: Codable {
    let periodTempAvg: Double?
    let periodTempMin: Double?
    let periodTempMax: Double?
    let periodPressAvg: Double?
    let periodHumAvg: Double?
}

// MARK: - Timeline Entry для complication (WidgetKit)

struct SensorEntry: TimelineEntry {
    let date: Date
    let temperature: Double?
    let pressure: Double?
    let humidity: Double?
}
