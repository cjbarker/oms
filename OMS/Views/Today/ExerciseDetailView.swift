import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: RoutineItem

    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @Query private var equipmentProfiles: [EquipmentProfile]
    @StateObject private var restTimer = RestTimerService()
    @State private var showSwap = false
    @State private var swapping = false
    @State private var error: String?

    private var exercise: Exercise? { ExerciseCatalogService.shared.exercise(id: item.exerciseId) }
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let exercise {
                    Text(exercise.name).font(.largeTitle).bold()
                    Text(exercise.primaryMuscles.joined(separator: " · "))
                        .foregroundStyle(.secondary).font(.footnote)

                    YouTubePlayerView(videoId: exercise.youtubeId, searchQuery: exercise.youtubeSearch)
                        .aspectRatio(16/9, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if !exercise.cues.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Form cues").font(.headline)
                            ForEach(exercise.cues, id: \.self) { cue in
                                Label(cue, systemImage: "checkmark.circle")
                                    .font(.footnote)
                            }
                        }
                    }
                }

                if let line = item.coachLine, let p = profile {
                    CoachBubble(text: line, persona: p.coachPersona)
                }

                SetLoggerView(item: item, onLogged: {
                    restTimer.start(
                        seconds: item.restSec,
                        announce: profile.map { CoachVoice.betweenSets(persona: $0.coachPersona) }
                    )
                })

                HStack {
                    Button {
                        showSwap = true
                    } label: {
                        Label("Swap exercise", systemImage: "arrow.triangle.swap")
                    }
                    Spacer()
                }

                if let error {
                    Text(error).foregroundStyle(.red).font(.footnote)
                }
            }
            .padding()
        }
        .overlay(alignment: .bottom) {
            if restTimer.isRunning {
                RestTimerOverlay(timer: restTimer)
            }
        }
        .confirmationDialog("Swap this exercise", isPresented: $showSwap, titleVisibility: .visible) {
            ForEach(ExerciseSwapService.Reason.allCases) { reason in
                Button(reason.label) { Task { await performSwap(reason: reason) } }
            }
            Button("Cancel", role: .cancel) {}
        }
        .disabled(swapping)
    }

    private func performSwap(reason: ExerciseSwapService.Reason) async {
        guard let profile else { return }
        swapping = true
        defer { swapping = false }
        let owned = (equipmentProfiles.first(where: { $0.isActive }) ?? equipmentProfiles.first)?.equipment ?? []
        let swapper = ExerciseSwapService()
        if let newId = await swapper.swap(item: item, reason: reason, profile: profile, owned: owned) {
            item.exerciseId = newId
            try? modelContext.save()
        } else {
            error = "Couldn't find a safe alternative. Try another reason or edit manually."
        }
    }
}
