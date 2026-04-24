import SwiftUI

struct RestTimerOverlay: View {
    @ObservedObject var timer: RestTimerService

    var body: some View {
        VStack(spacing: 12) {
            Text("Rest").font(.caption).foregroundStyle(.secondary)
            Text("\(timer.remainingSec)s")
                .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
            ProgressView(value: Double(timer.totalSec - timer.remainingSec),
                         total: Double(max(timer.totalSec, 1)))
                .tint(.accentColor)
            HStack {
                Button { timer.extend(seconds: 15) } label: {
                    Label("+15s", systemImage: "plus")
                }
                Spacer()
                Button(role: .destructive) { timer.skip() } label: {
                    Label("Skip", systemImage: "forward.fill")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
        .transition(.move(edge: .bottom))
    }
}
