import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class RestTimerService: ObservableObject {
    @Published var remainingSec: Int = 0
    @Published var totalSec: Int = 0
    @Published var isRunning: Bool = false

    private var timer: Timer?

    /// Start a rest countdown. Replaces any active timer.
    func start(seconds: Int, announce: String? = nil) {
        stop()
        totalSec = seconds
        remainingSec = seconds
        isRunning = true
        if let announce { SpeechService.shared.speak(announce) }
        let t = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func skip() { stop(); SpeechService.shared.speak("Let's go.") }

    func extend(seconds: Int = 30) {
        remainingSec += seconds
        totalSec += seconds
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        remainingSec = 0
        totalSec = 0
    }

    private func tick() {
        guard remainingSec > 0 else {
            stop()
            SpeechService.shared.speak("Time. Let's go.")
            return
        }
        remainingSec -= 1
        #if canImport(UIKit)
        if [5, 3, 1].contains(remainingSec) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        if remainingSec == 0 {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        #endif
    }
}
