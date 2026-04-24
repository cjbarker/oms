import SwiftUI

struct RoutineView: View {
    @Bindable var routine: Routine

    private var groups: [(key: String, items: [RoutineItem])] {
        let sorted = routine.items.sorted { $0.order < $1.order }
        var byGroup: [String: [RoutineItem]] = [:]
        var order: [String] = []
        for item in sorted {
            let key = item.groupId ?? "straight-\(item.order)"
            if byGroup[key] == nil { order.append(key) }
            byGroup[key, default: []].append(item)
        }
        return order.map { ($0, byGroup[$0] ?? []) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !routine.focus.isEmpty {
                Text(routine.focus).font(.title2).bold()
            }
            if !routine.rationale.isEmpty {
                Text(routine.rationale).font(.footnote).foregroundStyle(.secondary)
            }

            ForEach(groups, id: \.key) { group in
                if group.items.count > 1 || group.items.first?.structure != .straight {
                    GroupHeader(structure: group.items.first?.structure ?? .straight)
                }
                ForEach(group.items) { item in
                    NavigationLink {
                        ExerciseDetailView(item: item)
                    } label: {
                        RoutineItemRow(item: item)
                    }.buttonStyle(.plain)
                }
            }

            NavigationLink("Edit routine") { RoutineEditorView(routine: routine) }
                .font(.footnote)
        }
    }
}

private struct GroupHeader: View {
    let structure: SetStructure
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "rectangle.connected.to.line.below")
            Text(structure.label).font(.caption).bold()
        }
        .foregroundStyle(.secondary)
        .padding(.top, 4)
    }
}

private struct RoutineItemRow: View {
    let item: RoutineItem
    private var exercise: Exercise? { ExerciseCatalogService.shared.exercise(id: item.exerciseId) }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise?.name ?? item.exerciseId).font(.headline)
                Text("\(item.targetSets) × \(item.targetReps) · rest \(item.restSec)s")
                    .font(.footnote).foregroundStyle(.secondary)
                if let line = item.coachLine { Text(line).font(.caption).italic() }
            }
            Spacer()
            ProgressRing(current: item.setLogs.count, target: item.targetSets)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct ProgressRing: View {
    let current: Int
    let target: Int
    var body: some View {
        ZStack {
            Circle().stroke(.quaternary, lineWidth: 3)
            Circle().trim(from: 0, to: min(1, Double(current) / Double(max(target, 1))))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(current)/\(target)").font(.caption.monospacedDigit()).bold()
        }
        .frame(width: 40, height: 40)
    }
}
