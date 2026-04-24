import SwiftUI

struct ContentView: View {
    @State private var selection: Tab = .today

    enum Tab: Hashable { case today, equipment, coach, profile, settings }

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tabItem { Label("Today", systemImage: "flame.fill") }
                .tag(Tab.today)

            EquipmentListView()
                .tabItem { Label("Equipment", systemImage: "dumbbell.fill") }
                .tag(Tab.equipment)

            CoachSelectionView()
                .tabItem { Label("Coach", systemImage: "megaphone.fill") }
                .tag(Tab.coach)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(Tab.profile)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    ContentView()
}
