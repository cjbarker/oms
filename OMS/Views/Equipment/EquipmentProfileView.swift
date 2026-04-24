import SwiftUI
import SwiftData

struct EquipmentProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EquipmentProfile.createdAt) private var profiles: [EquipmentProfile]
    @State private var showAdd = false
    @State private var newName = ""

    var body: some View {
        List {
            ForEach(profiles) { profile in
                HStack {
                    VStack(alignment: .leading) {
                        Text(profile.name).font(.headline)
                        Text(profile.equipment.map(\.label).joined(separator: ", "))
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if profile.isActive {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.accent)
                    } else {
                        Button("Activate") { activate(profile) }.font(.footnote)
                    }
                }
                .contentShape(Rectangle())
                .swipeActions {
                    Button(role: .destructive) {
                        modelContext.delete(profile)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Profiles")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: { Label("Add", systemImage: "plus") }
            }
        }
        .alert("New profile", isPresented: $showAdd) {
            TextField("Name (e.g. Travel)", text: $newName)
            Button("Create") {
                let trimmed = newName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                let p = EquipmentProfile(name: trimmed)
                modelContext.insert(p)
                newName = ""
            }
            Button("Cancel", role: .cancel) { newName = "" }
        }
    }

    private func activate(_ profile: EquipmentProfile) {
        for p in profiles { p.isActive = (p === profile) }
    }
}
