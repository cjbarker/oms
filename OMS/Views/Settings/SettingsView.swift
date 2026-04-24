import SwiftUI
import AVFoundation

struct SettingsView: View {
    @AppStorage(LLMConfig.Keys.mode) private var modeRaw: String = LLMBackendMode.remote.rawValue
    @AppStorage(LLMConfig.Keys.remoteEndpoint) private var endpoint: String = LLMConfig.defaultRemoteEndpoint
    @AppStorage(LLMConfig.Keys.remoteModel) private var model: String = LLMConfig.defaultRemoteModel
    @AppStorage(LLMConfig.Keys.autoRegenerate) private var autoRegenerate: Bool = false
    @AppStorage(LLMConfig.Keys.ttsEnabled) private var ttsEnabled: Bool = false
    @AppStorage(LLMConfig.Keys.ttsVoice) private var ttsVoice: String = ""
    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw: String = AppearanceMode.system.rawValue

    @State private var apiKeyDraft: String = KeychainService.loadAPIKey() ?? ""
    @State private var revealKey = false

    private var mode: LLMBackendMode {
        get { LLMBackendMode(rawValue: modeRaw) ?? .remote }
    }
    private var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
    }

    var body: some View {
        NavigationStack {
            Form {
                llmBackendSection
                if mode == .remote { remoteSection } else { localSection }
                appearanceSection
                coachSection
                routineSection
                privacySection
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Sections

    private var llmBackendSection: some View {
        Section("AI backend") {
            Picker("Backend", selection: Binding(
                get: { mode },
                set: { modeRaw = $0.rawValue }
            )) {
                ForEach(LLMBackendMode.allCases) { Text($0.label).tag($0) }
            }
            Text(mode.summary).font(.footnote).foregroundStyle(.secondary)
        }
    }

    private var remoteSection: some View {
        Section("Remote (Claude API)") {
            TextField("Endpoint URL", text: $endpoint)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Model", text: $model)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            HStack {
                Group {
                    if revealKey {
                        TextField("API key", text: $apiKeyDraft)
                    } else {
                        SecureField("API key", text: $apiKeyDraft)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                Button { revealKey.toggle() } label: {
                    Image(systemName: revealKey ? "eye.slash" : "eye")
                }
            }
            HStack {
                Button("Save key") {
                    try? KeychainService.saveAPIKey(apiKeyDraft)
                }
                Spacer()
                Button("Clear", role: .destructive) {
                    KeychainService.deleteAPIKey()
                    apiKeyDraft = ""
                }
            }
        }
    }

    private var localSection: some View {
        Section("On-device (Gemma 3 E4B)") {
            NavigationLink("Model download & status") { LocalModelView() }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Appearance", selection: Binding(
                get: { appearance },
                set: { appearanceRaw = $0.rawValue }
            )) {
                ForEach(AppearanceMode.allCases) { Text($0.label).tag($0) }
            }.pickerStyle(.segmented)
        }
    }

    private var coachSection: some View {
        Section("Spoken coach") {
            Toggle("Enable text-to-speech", isOn: $ttsEnabled)
            if ttsEnabled {
                Picker("Voice", selection: $ttsVoice) {
                    Text("Default").tag("")
                    ForEach(SpeechService.shared.availableVoices, id: \.identifier) { v in
                        Text(v.name).tag(v.identifier)
                    }
                }
            }
        }
    }

    private var routineSection: some View {
        Section("Routine") {
            Toggle("Auto-regenerate daily", isOn: $autoRegenerate)
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            NavigationLink("What is sent to the AI") { PrivacyDashboardView() }
        }
    }
}

// MARK: - Privacy dashboard (simple disclosure)

private struct PrivacyDashboardView: View {
    var body: some View {
        List {
            Section("Routine generation request includes") {
                Label("Name, age, sex, height, weight", systemImage: "person")
                Label("Activity level, experience, goals", systemImage: "figure.run")
                Label("Limitations, pain points, medical flags", systemImage: "cross.case")
                Label("Apple Health sleep, HRV, resting HR", systemImage: "heart")
                Label("Equipment profile contents", systemImage: "dumbbell")
                Label("Last 7 days of exercise ids (no weights)", systemImage: "calendar")
            }
            Section("Equipment photo analysis sends") {
                Label("One photo you choose (JPEG)", systemImage: "photo")
            }
            Section("In on-device mode") {
                Text("Nothing leaves your phone. Model runs locally via llama.cpp.")
            }
        }
        .navigationTitle("Privacy")
    }
}
