import AppKit
import CoreServices

final class EditorDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Launch Services delivers open events during startup, before this callback.
        NSApp.terminate(nil)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        do {
            let request = try FileRequest(urls: urls)
            let task = Process()
            task.executableURL = Bundle.main.resourceURL!.appendingPathComponent("myran-open-files")
            task.arguments = request.arguments
            let errors = Pipe()
            task.standardError = errors
            try task.run()
            // Drain before waiting, so a full error pipe cannot deadlock the launcher.
            let data = errors.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            guard task.terminationStatus == 0 else {
                throw FileLinkError(String(decoding: data, as: UTF8.self))
            }
        } catch {
            NSApp.activate(ignoringOtherApps: true)
            NSAlert(error: error).runModal()
        }
    }
}

if Array(CommandLine.arguments.dropFirst()) == ["--register-app"] {
    // Advertise document and custom-scheme support only. Never request new defaults.
    let status = LSRegisterURL(Bundle.main.bundleURL as CFURL, true)
    if status != noErr {
        fputs("Cannot register Myran Editor: \(status)\n", stderr)
        exit(1)
    }
} else if CommandLine.arguments.count > 1 {
    fputs("Choose file defaults manually in Finder. This app does not change them.\n", stderr)
    exit(1)
} else {
    let app = NSApplication.shared
    let delegate = EditorDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
}
