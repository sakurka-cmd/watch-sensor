import Foundation

// MARK: - Константы

enum AppConstants {
    static let appGroupId   = "group.com.sakurka.watchsensor"
    static let defaultServer = "http://192.168.0.3:5000"
    static let serverURLKey  = "serverURL"
}

// MARK: - API-клиент

final class SensorAPI {

    static let shared = SensorAPI()

    /// URL сервера (Flask :5000). Читается/пишется в общий UserDefaults (App Group).
    var serverURL: String {
        get {
            UserDefaults(suiteName: AppConstants.appGroupId)?
                .string(forKey: AppConstants.serverURLKey)
                ?? AppConstants.defaultServer
        }
        set {
            UserDefaults(suiteName: AppConstants.appGroupId)?
                .set(newValue, forKey: AppConstants.serverURLKey)
        }
    }

    /// JSON-декодер с auto snake_case -> camelCase
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - GET /api/latest

    func fetchLatest() async throws -> SensorLatest {
        let url = URL(string: "\(serverURL)/api/latest")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.unavailable
        }
        do {
            return try decoder.decode(SensorLatest.self, from: data)
        } catch {
            throw APIError.decode
        }
    }

    // MARK: - GET /api/stats?period=...

    func fetchStats(period: String = "day") async throws -> SensorStats {
        var components = URLComponents(string: "\(serverURL)/api/stats")!
        components.queryItems = [URLQueryItem(name: "period", value: period)]
        let (data, response) = try await URLSession.shared.data(from: components.url!)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.unavailable
        }
        do {
            return try decoder.decode(SensorStats.self, from: data)
        } catch {
            throw APIError.decode
        }
    }

    // MARK: - Ошибки

    enum APIError: LocalizedError {
        case unavailable
        case decode

        var errorDescription: String? {
            switch self {
            case .unavailable: return "Сервер недоступен"
            case .decode:       return "Ошибка данных"
            }
        }
    }
}
