import WidgetKit
import SwiftUI

// MARK: - Widget

struct SensorWidget: Widget {
    let kind = "SensorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SensorProvider()) { entry in
            SensorWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Датчик")
        .description("Температура, давление и влажность с домашней метеостанции")
        .supportedFamilies([
            .circularSmall,
            .corner,
            .graphicCircular,
            .graphicCorner
        ])
    }
}

// MARK: - Router

struct SensorWidgetEntryView: View {
    let entry: SensorEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .circularSmall:
            CircularSmallView(entry: entry)
        case .corner:
            CornerGaugeView(entry: entry)
        case .graphicCircular:
            GraphicCircularView(entry: entry)
        case .graphicCorner:
            GraphicCornerView(entry: entry)
        default:
            CircularSmallView(entry: entry)
        }
    }
}

// MARK: - Circular Small (маленький кружок на циферблате)

struct CircularSmallView: View {
    let entry: SensorEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text(entry.temperature.map {
                    "\($0, specifier: "%.0f")°"
                } ?? "--°")
                .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(.orange)
        }
    }
}

// MARK: - Corner (gauge в углу циферблата)

struct CornerGaugeView: View {
    let entry: SensorEntry

    /// Диапазон для gauge: 0...40 °C (для типичных бытовых условий)
    private let tempRange: ClosedRange<Double> = 0...40

    private var gaugeValue: Double {
        guard let t = entry.temperature else { return 20 }
        return min(max(t, tempRange.lowerBound), tempRange.upperBound)
    }

    var body: some View {
        Gauge(value: gaugeValue, in: tempRange) {
            Text("°C")
        } currentValueLabel: {
            Text(entry.temperature.map {
                "\($0, specifier: "%.1f")"
            } ?? "--.-")
        }
        .gaugeStyle(.accessoryCircular)
        .tint(.orange)
    }
}

// MARK: - Graphic Circular (большой круг с иконкой)

struct GraphicCircularView: View {
    let entry: SensorEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "thermometer.medium")
                    .font(.body)
                    .foregroundColor(.orange)

                Text(entry.temperature.map {
                    "\($0, specifier: "%.1f")°"
                } ?? "--.-°")
                .font(.title2.bold())
                .foregroundColor(.orange)
            }
        }
    }
}

// MARK: - Graphic Corner (два текстовых значения в углу)

struct GraphicCornerView: View {
    let entry: SensorEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                Image(systemName: "thermometer.medium")
                    .font(.caption2)
                Text(entry.temperature.map {
                    "\($0, specifier: "%.1f")°C"
                } ?? "--.-°C")
                .fontWeight(.semibold)
            }
            .foregroundColor(.orange)

            HStack(spacing: 2) {
                Image(systemName: "drop")
                    .font(.caption2)
                Text(entry.humidity.map {
                    "\(Int($0))%"
                } ?? "--%")
            }
            .foregroundColor(.cyan)
        }
    }
}
