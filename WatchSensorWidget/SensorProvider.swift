import WidgetKit
import SwiftUI

// MARK: - TimelineProvider

struct SensorProvider: TimelineProvider {

    /// Placeholder — показывается при добавлении complication на циферблат
    func placeholder(in context: Context) -> SensorEntry {
        SensorEntry(
            date: Date(),
            temperature: 21.5,
            pressure: 740.0,
            humidity: 55.0
        )
    }

    /// Snapshot — предварительный просмотр в галерее complications
    func getSnapshot(in context: Context, completion: @escaping (SensorEntry) -> Void) {
        Task {
            await fetchAndDeliver(completion: completion)
        }
    }

    /// Timeline — основное обновление (система вызывает по расписанию)
    func getTimeline(in context: Context, completion: @escaping (Timeline<SensorEntry>) -> Void) {
        Task {
            await fetchAndDeliverTimeline(completion: completion)
        }
    }

    // MARK: - Network

    private func fetchAndDeliver(completion: @escaping (SensorEntry) -> Void) async {
        do {
            let data = try await SensorAPI.shared.fetchLatest()
            let entry = SensorEntry(
                date: Date(),
                temperature: data.temperature,
                pressure: data.pressure,
                humidity: data.humidity
            )
            completion(entry)
        } catch {
            // Плейсхолдер если сервер недоступен
            completion(SensorEntry(date: Date(), temperature: nil, pressure: nil, humidity: nil))
        }
    }

    private func fetchAndDeliverTimeline(completion: @escaping (Timeline<SensorEntry>) -> Void) async {
        var entry: SensorEntry

        do {
            let data = try await SensorAPI.shared.fetchLatest()
            entry = SensorEntry(
                date: Date(),
                temperature: data.temperature,
                pressure: data.pressure,
                humidity: data.humidity
            )
        } catch {
            entry = SensorEntry(date: Date(), temperature: nil, pressure: nil, humidity: nil)
        }

        // Следующее обновление: минимум через 15 минут (watchOS restriction)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
