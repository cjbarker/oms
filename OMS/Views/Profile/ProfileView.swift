import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first {
                    ProfileEditor(profile: profile)
                } else {
                    ContentUnavailableView("No profile",
                                           systemImage: "person.crop.circle.badge.questionmark",
                                           description: Text("Finish onboarding to build your profile."))
                }
            }
            .navigationTitle("Profile")
        }
    }
}

private struct ProfileEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Name", text: $profile.name)
                DatePicker("Birthdate", selection: Binding(
                    get: { profile.birthdate ?? Date() },
                    set: { profile.birthdate = $0 }
                ), displayedComponents: .date)
                Picker("Sex", selection: Binding(
                    get: { profile.sex },
                    set: { profile.sexRaw = $0.rawValue }
                )) { ForEach(Sex.allCases) { Text($0.label).tag($0) } }
                Picker("Units", selection: Binding(
                    get: { profile.units },
                    set: { profile.unitsRaw = $0.rawValue }
                )) { ForEach(Units.allCases) { Text($0.label).tag($0) } }
            }

            Section("Body") {
                HStack {
                    Text("Height")
                    Spacer()
                    Text("\(Int(profile.heightCm)) cm")
                }
                Slider(value: $profile.heightCm, in: 120...220, step: 1)
                HStack {
                    Text("Weight")
                    Spacer()
                    Text("\(Int(profile.weightKg)) kg")
                }
                Slider(value: $profile.weightKg, in: 40...200, step: 1)
            }

            Section("Training") {
                Picker("Activity level", selection: Binding(
                    get: { profile.activityLevel },
                    set: { profile.activityLevelRaw = $0.rawValue }
                )) { ForEach(ActivityLevel.allCases) { Text($0.label).tag($0) } }
                Picker("Experience", selection: Binding(
                    get: { profile.experience },
                    set: { profile.experienceRaw = $0.rawValue }
                )) { ForEach(TrainingExperience.allCases) { Text($0.label).tag($0) } }
                Stepper("Sessions/wk: \(profile.sessionsPerWeekTarget)",
                        value: $profile.sessionsPerWeekTarget, in: 2...6)
                Picker("Minutes/session", selection: $profile.sessionMinutesTarget) {
                    ForEach([20, 30, 45, 60, 75, 90], id: \.self) { Text("\($0)").tag($0) }
                }
            }

            Section("Goals") {
                ForEach(FitnessGoal.allCases) { goal in
                    Toggle(goal.label, isOn: Binding(
                        get: { profile.primaryGoals.contains(goal) },
                        set: { isOn in
                            var set = Set(profile.primaryGoals)
                            if isOn { set.insert(goal) } else { set.remove(goal) }
                            profile.primaryGoalsRaw = Array(set).map(\.rawValue)
                        }
                    ))
                }
            }

            Section("Limitations") {
                TextField("Notes", text: $profile.painPoints, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section {
                Button("Save", action: save)
            }
        }
    }

    private func save() { try? modelContext.save() }
}
