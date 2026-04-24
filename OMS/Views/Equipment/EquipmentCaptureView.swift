import SwiftUI
import PhotosUI
import SwiftData

struct EquipmentCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [EquipmentProfile]

    @State private var pickerItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var detected: [EquipmentType] = []
    @State private var analyzing = false
    @State private var error: String?

    private var active: EquipmentProfile? {
        profiles.first(where: { $0.isActive }) ?? profiles.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let image {
                        Image(uiImage: image)
                            .resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        ContentUnavailableView("Scan your gym",
                                               systemImage: "camera.viewfinder",
                                               description: Text("Take a photo (or choose one) showing your equipment. The AI coach will list what it sees."))
                    }

                    PhotosPicker("Choose photo", selection: $pickerItem, matching: .images)
                        .buttonStyle(.bordered)

                    if analyzing { ProgressView("Analyzing…") }
                    if let error { Text(error).foregroundStyle(.red).font(.footnote) }

                    if !detected.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Detected").font(.headline)
                            ForEach(detected, id: \.self) { item in
                                Label(item.label, systemImage: item.symbol)
                            }
                            Button {
                                mergeIntoActive()
                                dismiss()
                            } label: {
                                Label("Add to \(active?.name ?? "profile")", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(active == nil)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Scan equipment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: pickerItem) { _, newValue in
                Task { await loadAndAnalyze(item: newValue) }
            }
        }
    }

    private func loadAndAnalyze(item: PhotosPickerItem?) async {
        guard let item else { return }
        error = nil
        detected = []
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            error = "Could not load image."
            return
        }
        image = UIImage(data: data)
        guard let jpeg = image?.jpegData(compressionQuality: 0.85) ?? data as Data? else { return }

        if !LLMRouter.shared.visionSupported {
            error = "Photo analysis needs the Remote backend. Switch in Settings."
            return
        }
        guard LLMRouter.shared.isReady else {
            error = "Add your API key in Settings to use photo analysis."
            return
        }

        analyzing = true
        defer { analyzing = false }
        do {
            detected = try await EquipmentAnalyzer().analyze(imageData: jpeg)
            if detected.isEmpty { error = "No equipment recognized — try a clearer angle." }
        } catch let err as LLMError {
            self.error = err.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func mergeIntoActive() {
        guard let active else { return }
        var current = Set(active.equipment)
        current.formUnion(detected)
        active.equipment = Array(current).sorted { $0.label < $1.label }
    }
}
