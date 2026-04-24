import SwiftUI
import SwiftData

struct SetLoggerView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: RoutineItem

    /// Called when a new set is logged so the parent can kick off the rest timer.
    var onLogged: () -> Void

    @State private var draftWeight: String = ""
    @State private var draftReps: String = ""
    @State private var draftRPE: Double = 7

    private var nextSetIndex: Int { item.setLogs.count + 1 }
    private var isComplete: Bool { nextSetIndex > item.targetSets }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sets").font(.headline)

            ForEach(item.setLogs.sorted(by: { $0.setIndex < $1.setIndex }), id: \.setIndex) { log in
                HStack {
                    Text("Set \(log.setIndex)").bold().frame(width: 60, alignment: .leading)
                    Text(log.weightKg.map { "\(String(format: "%g", $0)) kg" } ?? "bw").frame(width: 70, alignment: .leading)
                    Text("\(log.reps) reps").frame(width: 70, alignment: .leading)
                    if let rpe = log.rpe { Text("RPE \(String(format: "%g", rpe))").foregroundStyle(.secondary) }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                }
                .font(.footnote.monospacedDigit())
            }

            if !isComplete {
                VStack(spacing: 8) {
                    HStack {
                        Text("Set \(nextSetIndex) of \(item.targetSets)").font(.subheadline).bold()
                        Spacer()
                        Text("Target: \(item.targetReps)").font(.footnote).foregroundStyle(.secondary)
                    }
                    HStack {
                        TextField("Weight (kg)", text: $draftWeight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                        TextField("Reps", text: $draftReps)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("RPE \(String(format: "%.0f", draftRPE))").frame(width: 60, alignment: .leading)
                        Slider(value: $draftRPE, in: 4...10, step: 1)
                    }
                    Button {
                        logSet()
                    } label: {
                        Label("Log set", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canLog)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Text("All sets logged. ").foregroundStyle(.green).font(.footnote)
            }
        }
    }

    private var canLog: Bool {
        Int(draftReps) != nil
    }

    private func logSet() {
        guard let reps = Int(draftReps), reps > 0 else { return }
        let weight = Double(draftWeight.replacingOccurrences(of: ",", with: "."))
        let log = SetLog(setIndex: nextSetIndex, weightKg: weight, reps: reps, rpe: draftRPE)
        log.item = item
        modelContext.insert(log)
        item.setLogs.append(log)
        try? modelContext.save()
        draftReps = ""
        onLogged()
    }
}
