#if !LITE
import Foundation
import AppKit

/// Manages the caption-app Python server lifecycle. Launches it as a subprocess
/// when the YT-Downloader app starts and keeps it alive while we're running.
/// Exposes the local URL the embedded WebView should load.
@MainActor
final class CaptionAppService: ObservableObject {

    enum Status: Equatable {
        case stopped
        case starting
        case running
        case failed(String)
    }

    @Published var status: Status = .stopped

    static let port = 8765
    static let url = URL(string: "http://127.0.0.1:\(port)")!

    private let captionAppRoot = URL(fileURLWithPath: "/Users/ilans/caption-app")
    private var process: Process?

    var isRunning: Bool {
        if case .running = status { return true }
        return false
    }

    /// Try to start caption-app's Python server. Idempotent — repeat calls are no-ops
    /// while the process is alive. If the venv doesn't exist, status flips to .failed.
    func start() {
        if isRunning || status == .starting { return }
        status = .starting

        let venvPython = captionAppRoot.appendingPathComponent(".venv/bin/python")
        let appPy = captionAppRoot.appendingPathComponent("app.py")

        guard FileManager.default.isExecutableFile(atPath: venvPython.path),
              FileManager.default.fileExists(atPath: appPy.path) else {
            status = .failed("caption-app not found at \(captionAppRoot.path). Make sure .venv exists and app.py is present.")
            return
        }

        // If something's already on the port (user started it manually), just trust it.
        if portInUse() {
            status = .running
            return
        }

        let proc = Process()
        proc.executableURL = venvPython
        proc.arguments = [appPy.path]
        proc.currentDirectoryURL = captionAppRoot
        // Inherit env (OPENAI_API_KEY, ANTHROPIC_API_KEY, PATH from launchd or shell).
        var env = ProcessInfo.processInfo.environment
        env["CAPTION_APP_DIR"] = NSTemporaryDirectory() + "caption-app-jobs"
        proc.environment = env
        // Discard output — caption-app's own logging is enough; we just need to keep it alive.
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()
        proc.terminationHandler = { [weak self] _ in
            Task { @MainActor in
                self?.status = .failed("Server exited.")
                self?.process = nil
            }
        }

        do {
            try proc.run()
        } catch {
            status = .failed("Could not launch: \(error.localizedDescription)")
            return
        }
        process = proc

        // Poll until the server is actually serving.
        Task { [weak self] in
            for _ in 0..<60 {  // ~30 seconds total
                if Task.isCancelled { return }
                try? await Task.sleep(nanoseconds: 500_000_000)
                if await self?.ping() == true {
                    await MainActor.run { self?.status = .running }
                    return
                }
                if let s = await self?.status, case .failed = s { return }
            }
            await MainActor.run {
                if let self = self, !self.isRunning {
                    self.status = .failed("Server didn't respond within 30s.")
                }
            }
        }
    }

    func stop() {
        process?.terminate()
        process = nil
        status = .stopped
    }

    private func portInUse() -> Bool {
        let s = socket(AF_INET, SOCK_STREAM, 0)
        defer { close(s) }
        guard s >= 0 else { return false }
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(UInt16(Self.port).bigEndian)
        addr.sin_addr = in_addr(s_addr: in_addr_t(0x7F000001).bigEndian)  // 127.0.0.1
        let connected = withUnsafePointer(to: &addr) { ptr -> Int32 in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sptr in
                connect(s, sptr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        return connected == 0
    }

    /// Returns true if caption-app's HTTP server is responding.
    private func ping() async -> Bool {
        var req = URLRequest(url: Self.url.appendingPathComponent("/"))
        req.timeoutInterval = 1.0
        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            return (resp as? HTTPURLResponse)?.statusCode ?? 0 < 500
        } catch {
            return false
        }
    }

    /// Upload a downloaded video to caption-app's /upload endpoint.
    /// Returns the URL to navigate the WebView to (typically just the root after upload).
    func uploadVideo(_ file: URL) async throws {
        guard isRunning else { return }
        let url = Self.url.appendingPathComponent("/upload")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let fileData = try Data(contentsOf: file)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(file.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body
        request.timeoutInterval = 120
        _ = try await URLSession.shared.data(for: request)
    }
}
#endif
