import Darwin
import Foundation

@main
struct LauncherTests {
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let shell = URL(fileURLWithPath: "/bin/sh")

        var disposition = sigaction()
        precondition(sigaction(SIGCHLD, nil, &disposition) == 0)
        for policy in ["ignored", "handler", "automatic"] {
            var unsupported = disposition
            if policy == "ignored" {
                signal(SIGCHLD, SIG_IGN)
            } else {
                if policy == "handler" {
                    unsupported.__sigaction_u.__sa_handler = { _ in }
                } else {
                    unsupported.sa_flags |= SA_NOCLDWAIT
                }
                precondition(sigaction(SIGCHLD, &unsupported, nil) == 0)
            }
            expectFailure("exclusive child reaping") {
                try EditorLauncher.run(executable: shell, arguments: ["-c", ":"])
            }
            precondition(sigaction(SIGCHLD, &disposition, nil) == 0)
        }

        try EditorLauncher.run(executable: shell, arguments: ["-c", ":"])
        try EditorLauncher.run(executable: shell, arguments: ["-c", "printf ignored"])
        expectFailure("expected failure") {
            try EditorLauncher.run(executable: shell, arguments: ["-c", "printf 'expected failure' >&2; exit 7"])
        }
        expectFailure("diagnostic limit") {
            try EditorLauncher.run(executable: shell, arguments: ["-c", "while :; do printf 'error message\\n' >&2; done"])
        }
        expectFailure("timed out") {
            try EditorLauncher.run(executable: shell, arguments: ["-c", "exec /bin/sleep 30"], timeout: 0.15)
        }
        expectFailure("timed out") {
            try EditorLauncher.run(executable: shell, arguments: ["-c", "exec 2>&-; exec /bin/sleep 30"], timeout: 0.15)
        }
        expectFailure("start editor launcher") {
            try EditorLauncher.run(executable: directory.appendingPathComponent("missing"), arguments: [])
        }

        // A descendant retaining stderr must not hold EOF open after its leader exits.
        let marker = directory.appendingPathComponent("descendant-survived")
        let start = ProcessInfo.processInfo.systemUptime
        try EditorLauncher.run(executable: shell,
            arguments: ["-c", "(/bin/sleep 1; /usr/bin/touch \"$1\") & exit 0", "fixture", marker.path])
        precondition(ProcessInfo.processInfo.systemUptime - start < 1)
        Thread.sleep(forTimeInterval: 1.2)
        precondition(!FileManager.default.fileExists(atPath: marker.path))

        let sibling = Process()
        sibling.executableURL = URL(fileURLWithPath: "/bin/sleep")
        sibling.arguments = ["30"]
        try sibling.run()
        defer { sibling.terminate(); sibling.waitUntilExit() }
        expectFailure("timed out") {
            try EditorLauncher.run(executable: shell, arguments: ["-c", "exec /bin/sleep 30"], timeout: 0.15)
        }
        precondition(sibling.isRunning)
        // Every error path must release admission once its owned child is reaped.
        try EditorLauncher.run(executable: shell, arguments: ["-c", ":"])
        print("PASS: bounded native helper diagnostics and waits, descendant cleanup, sibling preservation")
    }

    static func expectFailure(_ message: String, run: () throws -> Void) {
        let start = ProcessInfo.processInfo.systemUptime
        do {
            try run()
            preconditionFailure("Expected launcher failure containing: \(message)")
        } catch {
            precondition(error.localizedDescription.contains(message), error.localizedDescription)
        }
        precondition(ProcessInfo.processInfo.systemUptime - start < 2)
    }
}
