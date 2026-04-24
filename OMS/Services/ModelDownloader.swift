import Foundation
import CryptoKit

/// Background, resumable downloader for the on-device model file.
@MainActor
final class ModelDownloader: NSObject, ObservableObject {
    static let shared = ModelDownloader()

    enum State: Equatable {
        case idle
        case downloading(bytesReceived: Int64, total: Int64)
        case paused(bytesReceived: Int64, total: Int64)
        case verifying
        case complete
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published var computedSHA: String?

    private var task: URLSessionDownloadTask?
    private var session: URLSession!
    private var resumeData: Data?
    private let resumeDataURL: URL

    private override init() {
        let fm = FileManager.default
        let dir = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask,
                              appropriateFor: nil, create: true)
        self.resumeDataURL = (dir ?? fm.temporaryDirectory)
            .appendingPathComponent("model-resume.data")
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.oms.model-download")
        config.allowsCellularAccess = false
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        self.resumeData = try? Data(contentsOf: resumeDataURL)
        if LLMConfig.isLocalModelPresent { self.state = .complete }
    }

    func start() {
        guard let url = LLMConfig.localSourceURL else {
            state = .failed("Invalid source URL.")
            return
        }
        if case .downloading = state { return }
        if let data = resumeData {
            task = session.downloadTask(withResumeData: data)
        } else {
            task = session.downloadTask(with: url)
        }
        task?.resume()
        state = .downloading(bytesReceived: 0, total: 0)
    }

    func pause() {
        guard let task else { return }
        task.cancel { [weak self] data in
            guard let self else { return }
            if let data {
                self.resumeData = data
                try? data.write(to: self.resumeDataURL, options: .atomic)
            }
            Task { @MainActor in
                if case let .downloading(got, total) = self.state {
                    self.state = .paused(bytesReceived: got, total: total)
                } else {
                    self.state = .idle
                }
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        resumeData = nil
        try? FileManager.default.removeItem(at: resumeDataURL)
        state = .idle
    }

    func delete() {
        try? FileManager.default.removeItem(at: LLMConfig.localFileURL)
        state = .idle
    }

    static func computeSHA256(at url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while autoreleasepool(invoking: {
            let chunk = try? handle.read(upToCount: 1_048_576)
            if let chunk, !chunk.isEmpty {
                hasher.update(data: chunk)
                return true
            }
            return false
        }) {}
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

extension ModelDownloader: URLSessionDownloadDelegate, URLSessionDelegate {
    nonisolated func urlSession(_ session: URLSession,
                                downloadTask: URLSessionDownloadTask,
                                didWriteData bytesWritten: Int64,
                                totalBytesWritten: Int64,
                                totalBytesExpectedToWrite: Int64) {
        Task { @MainActor in
            self.state = .downloading(bytesReceived: totalBytesWritten,
                                      total: totalBytesExpectedToWrite)
        }
    }

    nonisolated func urlSession(_ session: URLSession,
                                downloadTask: URLSessionDownloadTask,
                                didFinishDownloadingTo location: URL) {
        let dest = LLMConfig.localFileURL
        let fm = FileManager.default
        do {
            if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
            try fm.moveItem(at: location, to: dest)
        } catch {
            Task { @MainActor in self.state = .failed("Move failed: \(error.localizedDescription)") }
            return
        }

        Task { @MainActor in
            self.state = .verifying
            do {
                let sha = try Self.computeSHA256(at: dest)
                self.computedSHA = sha
                self.state = .complete
                try? FileManager.default.removeItem(at: self.resumeDataURL)
                self.resumeData = nil
            } catch {
                self.state = .failed("SHA check failed: \(error.localizedDescription)")
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession,
                                task: URLSessionTask,
                                didCompleteWithError error: Error?) {
        guard let error = error as NSError? else { return }
        if let data = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            Task { @MainActor in
                self.resumeData = data
                try? data.write(to: self.resumeDataURL, options: .atomic)
            }
        } else {
            Task { @MainActor in self.state = .failed(error.localizedDescription) }
        }
    }
}
