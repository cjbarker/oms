import SwiftUI
import SwiftData

struct EquipmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var equipmentProfiles: [EquipmentProfile]
    @State private var showCapture = false

    private var active: EquipmentProfile? {
        equipmentProfiles.first(where: { $0.isActive }) ?? equipmentProfiles.first
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        EquipmentProfileView()
                    } label: {
                        HStack {
                            Text("Active profile")
                            Spacer()
                            Text(active?.name ?? "—").foregroundStyle(.secondary)
                        }
                    }
                    Button {
                        showCapture = true
                    } label: {
                        Label("Scan equipment with camera", systemImage: "camera.fill")
                    }
                }
                if let active {
                    Section("In this profile") {
                        if active.equipment.isEmpty {
                            Text("No equipment — bodyweight only.").foregroundStyle(.secondary).font(.footnote)
                        } else {
                            ForEach(active.equipment, id: \.self) { item in
                                Label(item.label, systemImage: item.symbol)
                            }
                            .onDelete { offsets in
                                var list = active.equipment
                                list.remove(atOffsets: offsets)
                                active.equipment = list
                            }
                        }
                    }
                    Section {
                        NavigationLink("Add gear manually") { AddEquipmentView(profile: active) }
                    }
                }
            }
            .navigationTitle("Equipment")
            .sheet(isPresented: $showCapture) {
                EquipmentCaptureView()
            }
        }
    }
}

struct AddEquipmentView: View {
    @Bindable var profile: EquipmentProfile
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        List {
            ForEach(EquipmentType.allCases) { type in
                let isOwned = profile.equipment.contains(type)
                Button {
                    var e = profile.equipment
                    if isOwned { e.removeAll(where: { $0 == type }) } else { e.append(type) }
                    profile.equipment = e
                } label: {
                    HStack {
                        Label(type.label, systemImage: type.symbol)
                        Spacer()
                        if isOwned { Image(systemName: "checkmark") }
                    }
                }.foregroundStyle(.primary)
            }
        }
        .navigationTitle("All equipment")
    }
}
