import SwiftUI

struct HealthSummaryCard: View {
    let snapshot: HealthSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: readinessSymbol)
                Text("Recovery: \(snapshot.readiness.rawValue.capitalized)").font(.headline)
            }.foregroundStyle(readinessColor)

            Text(snapshot.readiness.label).font(.footnote).foregroundStyle(.secondary)

            HStack(spacing: 16) {
                metric("Sleep", snapshot.lastNightSleepHours.map { String(format: "%.1f h", $0) })
                metric("HRV", snapshot.hrvMs.map { "\(Int($0)) ms" })
                metric("Rest HR", snapshot.restingHeartRate.map { "\(Int($0))" })
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var readinessSymbol: String {
        switch snapshot.readiness {
        case .low:      return "bed.double.fill"
        case .moderate: return "battery.50"
        case .good:     return "bolt.fill"
        }
    }

    private var readinessColor: Color {
        switch snapshot.readiness {
        case .low:      return .orange
        case .moderate: return .yellow
        case .good:     return .green
        }
    }

    private func metric(_ title: String, _ value: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value ?? "—").font(.headline.monospacedDigit())
        }
    }
}
