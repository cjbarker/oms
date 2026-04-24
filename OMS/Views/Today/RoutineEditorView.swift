import SwiftUI
import SwiftData

struct RoutineEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var routine: Routine
    @State private var showingAdd = false

    var body: some View {
        List {
            Section("Session") {
                TextField("Focus", text: $routine.focus)
                TextField("Rationale", text: $routine.rationale, axis: .vertical)
                    .lineLimit(2...4)
            }
            Section("Exercises") {
                ForEach(routine.items.sorted(by: { $0.order < $1.order })) { item in
                    ItemRow(item: item)
                }
                .onDelete { offsets in
                    let sorted = routine.items.sorted(by: { $0.order < $1.order })
                    for idx in offsets {
                        let victim = sorted[idx]
                        routine.items.removeAll(where: { $0 === victim })
                        modelContext.delete(victim)
                    }
                    reorder()
                }
                .onMove { src, dst in
                    var sorted = routine.items.sorted(by: { $0.order < $1.order })
                    sorted.move(fromOffsets: src, toOffset: dst)
                    for (i, item) in sorted.enumerated() { item.order = i }
                }
            }
        }
        .navigationTitle("Edit routine")
        .toolbar {
            ToolbarItem(placement: .primaryAction) { EditButton() }
            ToolbarItem(placement: .bottomBar) {
                Button { showingAdd = true } label: { Label("Add exercise", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddExerciseSheet { id in
                let item = RoutineItem(exerciseId: id, order: routine.items.count)
                item.routine = routine
                routine.items.append(item)
                modelContext.insert(item)
            }
        }
    }

    private func reorder() {
        let sorted = routine.items.sorted(by: { $0.order < $1.order })
        for (i, item) in sorted.enumerated() { item.order = i }
    }
}

private struct ItemRow: View {
    @Bindable var item: RoutineItem
    private var exercise: Exercise? { ExerciseCatalogService.shared.exercise(id: item.exerciseId) }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise?.name ?? item.exerciseId).font(.headline)
            HStack {
                Stepper("Sets: \(item.targetSets)", value: $item.targetSets, in: 1...8)
            }
            HStack {
                TextField("Reps", text: $item.targetReps).textFieldStyle(.roundedBorder)
                Stepper("Rest \(item.restSec)s", value: $item.restSec, in: 0...300, step: 15)
            }
            Picker("Structure", selection: Binding(
                get: { item.structure },
                set: { item.structure = $0 }
            )) {
                ForEach(SetStructure.allCases, id: \.self) { s in Text(s.label).tag(s) }
            }.pickerStyle(.segmented)
        }
    }
}

private struct AddExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onPick: (String) -> Void
    @State private var search = ""
    private var exercises: [Exercise] { ExerciseCatalogService.shared.exercises }
    private var filtered: [Exercise] {
        exercises.filter {
            search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)
        }
    }
    var body: some View {
        NavigationStack {
            List(filtered) { e in
                Button {
                    onPick(e.id)
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(e.name).font(.headline)
                        Text(e.category.label).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .searchable(text: $search)
            .navigationTitle("Add exercise")
        }
    }
}
