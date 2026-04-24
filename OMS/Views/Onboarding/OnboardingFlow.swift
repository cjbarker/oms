import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @Environment(\.modelContext) private var modelContext
    @State private var store = OnboardingStore()
    @State private var sectionIndex = 0
    @State private var errorMessage: String?

    let onFinish: () -> Void

    enum Section: Int, CaseIterable, Identifiable {
        case welcome
        case persona
        case basics
        case anthro
        case activity
        case experience
        case availability
        case goals
        case limitations
        case medical
        case equipment
        case appearance
        case llmBackend
        case llmRemoteSetup
        case llmLocalSetup
        case summary

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .welcome:         return "Welcome"
            case .persona:         return "Pick your coach"
            case .basics:          return "The basics"
            case .anthro:          return "Body"
            case .activity:        return "Activity level"
            case .experience:      return "Training history"
            case .availability:    return "Availability"
            case .goals:           return "Goals"
            case .limitations:     return "Limitations"
            case .medical:         return "Medical"
            case .equipment:       return "Equipment"
            case .appearance:      return "Appearance"
            case .llmBackend:      return "AI coach"
            case .llmRemoteSetup:  return "API setup"
            case .llmLocalSetup:   return "On-device model"
            case .summary:         return "Ready"
            }
        }
    }

    private var orderedSections: [Section] {
        Section.allCases.filter { section in
            switch section {
            case .llmRemoteSetup: return store.llmMode == .remote
            case .llmLocalSetup:  return store.llmMode == .local
            default: return true
            }
        }
    }

    private var currentSection: Section { orderedSections[sectionIndex] }
    private var progress: Double { Double(sectionIndex + 1) / Double(orderedSections.count) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: progress).padding(.horizontal).padding(.top, 8)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        content(for: currentSection)
                    }
                    .padding()
                }
                if let error = errorMessage {
                    Text(error).foregroundStyle(.red).font(.footnote).padding(.horizontal)
                }
                HStack {
                    if sectionIndex > 0 {
                        Button("Back") { withAnimation { sectionIndex -= 1 } }
                    }
                    Spacer()
                    Button(currentSection == .summary ? "Let's go" : "Next") {
                        advance()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle(currentSection.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func advance() {
        errorMessage = nil
        if let error = store.validate(section: currentSection) {
            errorMessage = error
            return
        }
        if currentSection == .summary {
            store.commit(modelContext: modelContext)
            onFinish()
            return
        }
        withAnimation { sectionIndex += 1 }
    }

    // MARK: - Sections

    @ViewBuilder
    private func content(for section: Section) -> some View {
        switch section {
        case .welcome:       WelcomeStep()
        case .persona:       PersonaStep(store: store)
        case .basics:        BasicsStep(store: store)
        case .anthro:        AnthroStep(store: store)
        case .activity:      ActivityStep(store: store)
        case .experience:    ExperienceStep(store: store)
        case .availability:  AvailabilityStep(store: store)
        case .goals:         GoalsStep(store: store)
        case .limitations:   LimitationsStep(store: store)
        case .medical:       MedicalStep(store: store)
        case .equipment:     EquipmentStep(store: store)
        case .appearance:    AppearanceStep(store: store)
        case .llmBackend:    LLMBackendStep(store: store)
        case .llmRemoteSetup: LLMRemoteSetupStep(store: store)
        case .llmLocalSetup:  LLMLocalSetupStep(store: store)
        case .summary:       SummaryStep(store: store)
        }
    }
}

// MARK: - Steps

private struct WelcomeStep: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome to OMS").font(.largeTitle).bold()
            Text("Old Man Strength — a private AI coach that builds your daily workout around your body, goals, limitations, and recovery.")
                .foregroundStyle(.secondary)
            Label("Your data lives on this device.", systemImage: "lock.shield")
            Label("You choose where the AI runs — cloud or on-device.", systemImage: "cpu")
            Label("Not medical advice. Clear major injuries with a clinician first.", systemImage: "cross.case")
        }
    }
}

private struct PersonaStep: View {
    @Bindable var store: OnboardingStore
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What kind of coach do you want in your ear?").font(.headline)
            ForEach(CoachPersona.allCases) { p in
                Button {
                    store.persona = p
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(p.label).font(.headline)
                            Spacer()
                            if store.persona == p { Image(systemName: "checkmark.circle.fill") }
                        }
                        Text(p.sampleLine).font(.footnote).foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(store.persona == p ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct BasicsStep: View {
    @Bindable var store: OnboardingStore
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Preferred name", text: $store.name).textFieldStyle(.roundedBorder)
            DatePicker("Birthdate", selection: $store.birthdate, displayedComponents: .date)
            Picker("Sex (for calorie/strength norms)", selection: $store.sex) {
                ForEach(Sex.allCases) { Text($0.label).tag($0) }
            }
            Picker("Units", selection: $store.units) {
                ForEach(Units.allCases) { Text($0.label).tag($0) }
            }
        }
    }
}

private struct AnthroStep: View {
    @Bindable var store: OnboardingStore
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Height")
                Spacer()
                Text("\(Int(store.heightCm)) cm")
            }
            Slider(value: $store.heightCm, in: 120...220, step: 1)
            HStack {
                Text("Weight")
                Spacer()
                Text("\(Int(store.weightKg)) kg")
            }
            Slider(value: $store.weightKg, in: 40...200, step: 1)
            TextField("Body fat %% (optional)", text: $store.bodyFatPct)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct ActivityStep: View {
    @Bindable var store: OnboardingStore
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(ActivityLevel.allCases) { lvl in
                Button { store.activityLevel = lvl } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(lvl.label).font(.headline)
                            Text(lvl.detail).font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if store.activityLevel == lvl { Image(systemName: "checkmark.circle.fill") }
                    }
                    .padding()
                    .background(store.activityLevel == lvl ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }.buttonStyle(.plain)
            }
        }
    }
}

private struct ExperienceStep: View {
    @Bindable var store: OnboardingStore
    private let lifts = ["Squat", "Deadlift", "Bench press", "Overhead press", "Pull-up"]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Experience", selection: $store.experience) {
                ForEach(TrainingExperience.allCases) { Text($0.label).tag($0) }
            }.pickerStyle(.segmented)

            Text("Lifts you're comfortable with").font(.headline)
            ForEach(lifts, id: \.self) { lift in
                Toggle(lift, isOn: Binding(
                    get: { store.familiarLifts.contains(lift) },
                    set: { isOn in
                        if isOn { store.familiarLifts.insert(lift) } else { store.familiarLifts.remove(lift) }
                    }
                ))
            }
        }
    }
}

private struct AvailabilityStep: View {
    @Bindable var store: OnboardingStore
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Stepper("Sessions per week: \(store.sessionsPerWeekTarget)",
                    value: $store.sessionsPerWeekTarget, in: 2...6)
            Picker("Minutes per session", selection: $store.sessionMinutesTarget) {
                ForEach([20, 30, 45, 60, 75, 90], id: \.self) { Text("\($0) min").tag($0) }
            }.pickerStyle(.segmented)
        }
    }
}

private struct GoalsStep: View {
    @Bindable var store: OnboardingStore
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Primary goals (pick 1–2)").font(.headline)
            FlowLayoutChips(selection: $store.primaryGoals, allOptions: FitnessGoal.allCases,
                            label: { $0.label })
            Text("Secondary goals (optional)").font(.headline)
            FlowLayoutChips(selection: $store.secondaryGoals, allOptions: FitnessGoal.allCases,
                            label: { $0.label })
        }
    }
}

private struct LimitationsStep: View {
    @Bindable var store: OnboardingStore
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Anything we should work around?").font(.headline)
            FlowLayoutChips(selection: $store.limitationTags,
                            allOptions: Limitation.commonTags,
                            label: { $0 })
            Text("Notes for the coach").font(.subheadline).foregroundStyle(.secondary)
            TextEditor(text: $store.limitationNote)
                .frame(minHeight: 60)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
        }
    }
}

private struct MedicalStep: View {
    @Bindable var store: OnboardingStore
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Anything bothering you today?").font(.headline)
            TextField("e.g. tight hips, tweaky shoulder", text: $store.painPoints, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
            Text("Doctor-imposed restrictions").font(.headline)
            TextField("e.g. no overhead pressing", text: $store.medicalFlags, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
            Toggle("I have been cleared for exercise by a clinician", isOn: $store.clearedForExercise)
        }
    }
}

private struct EquipmentStep: View {
    @Bindable var store: OnboardingStore
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Starting equipment profile").font(.headline)
            Picker("", selection: $store.equipmentSet) {
                ForEach(OnboardingStore.StartingEquipmentSet.allCases) { Text($0.label).tag($0) }
            }.pickerStyle(.segmented)
            if !store.equipmentSet.defaultItems.isEmpty {
                Text("We'll pre-load: " +
                     store.equipmentSet.defaultItems.map(\.label).joined(separator: ", "))
                    .font(.footnote).foregroundStyle(.secondary)
            } else {
                Text("No equipment — bodyweight-first programming.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Text("You can capture your gym with a photo later from the Equipment tab.").font(.footnote)
        }
    }
}

private struct AppearanceStep: View {
    @Bindable var store: OnboardingStore
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How should OMS look?").font(.headline)
            Picker("", selection: $store.appearance) {
                ForEach(AppearanceMode.allCases) { Text($0.label).tag($0) }
            }.pickerStyle(.segmented)
            Text("You can change this any time from Settings.").font(.footnote).foregroundStyle(.secondary)
        }
    }
}

private struct LLMBackendStep: View {
    @Bindable var store: OnboardingStore
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Where should the AI coach run?").font(.headline)
            ForEach(LLMBackendMode.allCases) { mode in
                Button { store.llmMode = mode } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(mode.label).font(.headline)
                            Spacer()
                            if store.llmMode == mode { Image(systemName: "checkmark.circle.fill") }
                        }
                        Text(mode.summary).font(.footnote).foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(store.llmMode == mode ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }.buttonStyle(.plain)
            }
        }
    }
}

private struct LLMRemoteSetupStep: View {
    @Bindable var store: OnboardingStore
    @State private var revealKey = false
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Paste your API key").font(.headline)
            TextField("Endpoint URL", text: $store.remoteEndpoint)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Model", text: $store.remoteModel)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            HStack {
                Group {
                    if revealKey {
                        TextField("sk-ant-...", text: $store.apiKey)
                    } else {
                        SecureField("sk-ant-...", text: $store.apiKey)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                Button { revealKey.toggle() } label: {
                    Image(systemName: revealKey ? "eye.slash" : "eye")
                }
            }
            Text("Stored in the iOS Keychain. You can skip and configure later in Settings.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }
}

private struct LLMLocalSetupStep: View {
    @Bindable var store: OnboardingStore
    @StateObject private var dl = ModelDownloader.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gemma 3 E4B — Q4_K_M GGUF").font(.headline)
            Text("About 3 GB. Wi-Fi only by default. You can finish onboarding and download later from Settings.")
                .font(.footnote).foregroundStyle(.secondary)
            LocalModelStatusView()
        }
    }
}

private struct SummaryStep: View {
    @Bindable var store: OnboardingStore
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You're set").font(.largeTitle).bold()
            Text("\(store.persona.sampleLine)").italic()
            summaryRow("Coach", store.persona.label)
            summaryRow("Goals", (store.primaryGoals.map(\.label) + store.secondaryGoals.map(\.label)).joined(separator: ", "))
            summaryRow("Sessions", "\(store.sessionsPerWeekTarget)/wk × \(store.sessionMinutesTarget) min")
            summaryRow("Equipment", store.equipmentSet.label)
            summaryRow("AI", store.llmMode.label)
        }
    }
    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).foregroundStyle(.secondary).frame(width: 90, alignment: .leading)
            Text(value.isEmpty ? "—" : value)
        }
    }
}

// MARK: - Small reusable chip strip used by goals/limitations

private struct FlowLayoutChips<Value: Hashable>: View {
    @Binding var selection: Set<Value>
    let allOptions: [Value]
    let label: (Value) -> String
    var body: some View {
        WrapLayout(spacing: 8) {
            ForEach(Array(allOptions.enumerated()), id: \.offset) { _, item in
                let isOn = selection.contains(item)
                Button {
                    if isOn { selection.remove(item) } else { selection.insert(item) }
                } label: {
                    Text(label(item))
                        .padding(.vertical, 6).padding(.horizontal, 10)
                        .background(isOn ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }.buttonStyle(.plain)
            }
        }
    }
}

/// Wrap children onto multiple lines when they exceed the proposed width.
private struct WrapLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth.isFinite ? maxWidth : x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
