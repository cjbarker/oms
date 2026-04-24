import SwiftUI

struct LocalModelView: View {
    var body: some View {
        Form {
            Section("Model") {
                LabeledContent("File", value: LLMConfig.localFileName)
                LabeledContent("Source", value: LLMConfig.localSourceURL?.host ?? "—")
                    .font(.footnote)
            }
            Section("Status") { LocalModelStatusView() }
        }
        .navigationTitle("On-device model")
    }
}

/// Download progress + controls. Reused in onboarding and settings.
struct LocalModelStatusView: View {
    @StateObject private var dl = ModelDownloader.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch dl.state {
            case .idle:
                statusRow("Not downloaded")
                Button {
                    dl.start()
                } label: { Label("Download (~3 GB)", systemImage: "arrow.down.circle.fill") }
            case .downloading(let got, let total):
                progress(got: got, total: total, label: "Downloading")
                Button { dl.pause() } label: { Label("Pause", systemImage: "pause.fill") }
            case .paused(let got, let total):
                progress(got: got, total: total, label: "Paused")
                Button { dl.start() } label: { Label("Resume", systemImage: "play.fill") }
            case .verifying:
                statusRow("Verifying…")
                ProgressView()
            case .complete:
                statusRow("Ready")
                if let sha = dl.computedSHA {
                    Text("SHA-256: \(sha.prefix(16))…")
                        .font(.caption.monospaced()).foregroundStyle(.secondary)
                }
                Button(role: .destructive) {
                    dl.delete()
                } label: { Label("Delete model", systemImage: "trash") }
            case .failed(let msg):
                statusRow("Failed: \(msg)")
                Button {
                    dl.start()
                } label: { Label("Retry", systemImage: "arrow.clockwise") }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func progress(got: Int64, total: Int64, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.subheadline.bold())
            ProgressView(value: total > 0 ? Double(got) / Double(total) : 0)
            Text("\(byteString(got)) / \(total > 0 ? byteString(total) : "?")")
                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
        }
    }

    private func statusRow(_ text: String) -> some View {
        HStack {
            Text(text)
            Spacer()
        }
    }

    private func byteString(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
