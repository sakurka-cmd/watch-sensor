import SwiftUI

struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var serverURL: String = ""

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {

            Text("Сервер")
                .font(.headline)

            // Поле ввода URL
            TextField("http://...", text: $serverURL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .onAppear {
                    serverURL = SensorAPI.shared.serverURL
                }

            // Быстрые пресеты (подставить свой IP)
            HStack(spacing: 8) {
                presetButton("192.168.0.3")
                presetButton("192.168.1.5")
                presetButton("192.168.0.100")
            }
            .font(.caption2)

            // Кнопки
            HStack(spacing: 12) {
                Button("Отмена") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Сохранить") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .disabled(serverURL.isEmpty || !serverURL.hasPrefix("http"))
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private func presetButton(_ ip: String) {
        Button {
            serverURL = "http://\(ip):5000"
        } label: {
            Text(ip)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .foregroundColor(.secondary)
    }

    private func save() {
        // Убираем trailing slash если есть
        let cleaned = serverURL.trimmingCharacters(in: .whitespaces)
            .trimmingTrailingSlash
        SensorAPI.shared.serverURL = cleaned

        // Принудительно обновляем complication
        WidgetCenter.shared.reloadAllTimelines()

        dismiss()
    }
}

// MARK: - String extension

private extension String {
    var trimmingTrailingSlash: String {
        hasSuffix("/") ? String(dropLast()) : self
    }
}
