import SwiftUI
import SwiftData

@main
struct OMSApp: App {
    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw: String = AppearanceMode.system.rawValue
    @AppStorage("oms.onboarding.completed") private var onboardingCompleted: Bool = false

    private var appearance: AppearanceMode { AppearanceMode(rawValue: appearanceRaw) ?? .system }

    var body: some Scene {
        WindowGroup {
            RootView(onboardingCompleted: $onboardingCompleted)
                .preferredColorScheme(appearance.colorScheme)
        }
        .modelContainer(for: [
            UserProfile.self,
            Routine.self,
            RoutineItem.self,
            SetLog.self,
            Equipment.self,
            EquipmentProfile.self
        ])
    }
}

struct RootView: View {
    @Binding var onboardingCompleted: Bool

    var body: some View {
        if onboardingCompleted {
            ContentView()
        } else {
            OnboardingFlow(onFinish: { onboardingCompleted = true })
        }
    }
}
