import SwiftUI

struct ContentView: View {

    // MARK: - State

    @State private var latest: SensorLatest?
    @State private var isLoading = false
    @State private var error: String?
    @State private var lastRefresh: Date?
    @State private var showSettings = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {

                    // --- Температура ---
                    temperatureSection

                    Divider()

                    // --- Давление + Влажность ---
                    pressureHumiditySection

                    // --- Ошибка ---
                    if let error = error {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.caption2)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    // --- Время обновления ---
                    if let refreshed = lastRefresh {
                        Text("Обн: \(refreshed, format: .dateTime.hour().minute().second())")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("Датчик")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await refresh() } } label: {
                        Image(systemName: isLoading ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .task { await refresh() }
        }
    }

    // MARK: - Sections

    private var temperatureSection: some View {
        VStack(spacing: 2) {
            Text("Температура")
                .font(.caption2)
                .foregroundColor(.secondary)

            if isLoading && latest == nil {
                ProgressView()
                    .scaleEffect(0.6)
            } else if let temp = latest?.temperature {
                Text("\(temp, specifier: "%.1f")°C")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                    .contentTransition(.numericText())
            } else {
                Text("--.-°C")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
            }
        }
        .padding(.top, 4)
    }

    private var pressureHumiditySection: some View {
        HStack(spacing: 24) {
            // Давление
            VStack(spacing: 2) {
                Text("Давление")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if let press = latest?.pressure {
                    Text("\(press, specifier: "%.0f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .contentTransition(.numericText())
                } else {
                    Text("---")
                        .font(.title3)
                        .foregroundColor(.gray)
                }

                Text("мм рт.ст.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Влажность
            VStack(spacing: 2) {
                Text("Влажность")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if let hum = latest?.humidity {
                    Text("\(Int(hum))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .contentTransition(.numericText())
                } else {
                    Text("---%")
                        .font(.title3)
                        .foregroundColor(.gray)
                }

                Text("отн.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - API

    private func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            latest = try await SensorAPI.shared.fetchLatest()
            lastRefresh = Date()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
