import SwiftUI
import SwiftData

struct CoachSelectionView: View {
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            List {
                Section("Persona") {
                    ForEach(CoachPersona.allCases) { p in
                        Button {
                            if let profile { profile.coachPersona = p }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(p.label).font(.headline)
                                    Text(p.sampleLine).font(.footnote).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if profile?.coachPersona == p {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.accent)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                Section("Tone guidance sent to the AI") {
                    Text(profile?.coachPersona.toneGuidance ?? "").font(.footnote)
                }
            }
            .navigationTitle("Coach")
        }
    }
}
