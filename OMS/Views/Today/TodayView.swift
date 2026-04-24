import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \Routine.date, order: .reverse) private var routines: [Routine]
    @Query private var equipmentProfiles: [EquipmentProfile]

    @StateObject private var health = HealthKitService.shared
    @State private var generating = false
    @State private var error: String?

    private var profile: UserProfile? { profiles.first }
    private var todaysRoutine: Routine? {
        routines.first { Calendar.current.isDateInToday($0.date) }
    }
    private var activeProfile: EquipmentProfile? {
        equipmentProfiles.first(where: { $0.isActive }) ?? equipmentProfiles.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HealthSummaryCard(snapshot: health.latestSnapshot)
                    if let active = activeProfile {
                        HStack {
                            Label("Profile: \(active.name)", systemImage: "dumbbell.fill")
                                .font(.footnote)
                            Spacer()
                            NavigationLink("Switch") { EquipmentProfileView() }.font(.footnote)
                        }
                        .padding(.horizontal, 4)
                    }

                    if let routine = todaysRoutine {
                        if let p = profile, !routine.notes.isEmpty {
                            CoachBubble(text: routine.notes, persona: p.coachPersona)
                        }
                        RoutineView(routine: routine)
                    } else {
                        emptyStateCard
                    }

                    if let error { Text(error).foregroundStyle(.red).font(.footnote) }
                }
                .padding()
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await regenerate() }
                    } label: {
                        if generating { ProgressView() } else { Label("Regenerate", systemImage: "arrow.triangle.2.circlepath") }
                    }
                    .disabled(generating || profile == nil)
                }
            }
            .task {
                await health.requestAuthorization()
                await health.refreshSnapshot()
                if todaysRoutine == nil, UserDefaults.standard.bool(forKey: LLMConfig.Keys.autoRegenerate) {
                    await regenerate()
                }
            }
        }
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No routine for today yet").font(.headline)
            Text("Tap Regenerate above to build today's session from your profile, recovery, and equipment.")
                .foregroundStyle(.secondary).font(.footnote)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func regenerate() async {
        guard let profile else { return }
        generating = true
        defer { generating = false }
        error = nil

        let owned = activeProfile?.equipment ?? []
        let recent = Array(routines.prefix(7)).map { r -> RoutinePromptInput.RecentSession in
            RoutinePromptInput.RecentSession(
                daysAgo: max(0, Calendar.current.dateComponents([.day], from: r.date, to: Date()).day ?? 0),
                focus: r.focus,
                exerciseIds: r.items.map(\.exerciseId)
            )
        }

        do {
            let generator = RoutineGenerator()
            let new: Routine
            if LLMRouter.shared.isReady {
                new = try await generator.generate(
                    for: profile, snapshot: health.latestSnapshot,
                    owned: owned, recent: recent
                )
            } else {
                new = generator.fallback(for: profile, owned: owned)
            }
            // Replace any existing routine for today.
            if let existing = todaysRoutine { modelContext.delete(existing) }
            modelContext.insert(new)
            try? modelContext.save()
        } catch let err as LLMError {
            error = err.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }
}
