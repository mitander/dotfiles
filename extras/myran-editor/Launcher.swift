import Darwin
import Foundation

// The app owns one short-lived helper group, not the editors started by tmux.
enum EditorLauncher {
    private static let admission = DispatchSemaphore(value: 1)
    private static let stderrBytesMax = 16 * 1024

    static func run(executable: URL, arguments: [String], timeout: TimeInterval = 30) throws {
        guard admission.wait(timeout: .now()) == .success else {
            throw FileLinkError("The previous editor launcher is still being cleaned up.")
        }
        var releaseAdmission = true
        defer { if releaseAdmission { admission.signal() } }

        var disposition = sigaction()
        guard sigaction(SIGCHLD, nil, &disposition) == 0 else {
            throw systemError("inspect child ownership", errno)
        }
        guard disposition.__sigaction_u.__sa_handler == nil,
              disposition.sa_flags & SA_NOCLDWAIT == 0 else {
            throw FileLinkError("The editor launcher requires exclusive child reaping.")
        }

        var descriptors: [Int32] = [0, 0]
        guard pipe(&descriptors) == 0 else { throw systemError("create launcher pipe", errno) }
        defer { close(descriptors[0]) }
        var writerOpen = true
        defer { if writerOpen { close(descriptors[1]) } }
        for index in descriptors.indices where descriptors[index] <= STDERR_FILENO {
            let duplicate = fcntl(descriptors[index], F_DUPFD_CLOEXEC, 3)
            guard duplicate != -1 else { throw systemError("reserve launcher pipe", errno) }
            close(descriptors[index])
            descriptors[index] = duplicate
        }
        guard fcntl(descriptors[0], F_SETFL, O_NONBLOCK) != -1 else {
            throw systemError("configure launcher pipe", errno)
        }

        var actions: posix_spawn_file_actions_t?
        try check(posix_spawn_file_actions_init(&actions))
        defer { posix_spawn_file_actions_destroy(&actions) }
        try check(posix_spawn_file_actions_addopen(&actions, STDIN_FILENO, "/dev/null", O_RDONLY, 0))
        try check(posix_spawn_file_actions_addopen(&actions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0))
        try check(posix_spawn_file_actions_adddup2(&actions, descriptors[1], STDERR_FILENO))
        try check(posix_spawn_file_actions_addclose(&actions, descriptors[0]))
        try check(posix_spawn_file_actions_addclose(&actions, descriptors[1]))

        var attributes: posix_spawnattr_t?
        try check(posix_spawnattr_init(&attributes))
        defer { posix_spawnattr_destroy(&attributes) }
        try check(posix_spawnattr_setpgroup(&attributes, 0))
        try check(posix_spawnattr_setflags(&attributes,
            Int16(POSIX_SPAWN_SETPGROUP | POSIX_SPAWN_CLOEXEC_DEFAULT)))
        var process: pid_t = 0
        let environment = ProcessInfo.processInfo.environment.map { "\($0.key)=\($0.value)" }
        try withStrings([executable.path] + arguments) { argv in
            try withStrings(environment) { envp in
                try check(posix_spawn(&process, executable.path, &actions, &attributes, argv, envp))
            }
        }
        close(descriptors[1])
        writerOpen = false

        defer {
            // waitid(WNOWAIT) keeps the child PID reserved until this final group signal.
            kill(-process, SIGKILL)
            let deadline = ProcessInfo.processInfo.systemUptime + 0.5
            var status: Int32 = 0
            var reaped = false
            repeat {
                let result = waitpid(process, &status, WNOHANG)
                if result == process || (result == -1 && errno == ECHILD) {
                    reaped = true
                    break
                }
                poll(nil, 0, 10)
            } while ProcessInfo.processInfo.systemUptime < deadline
            if !reaped {
                // An OS-stalled reap must not extend the UI's wait or admit more helpers.
                releaseAdmission = false
                let child = process
                DispatchQueue.global().async {
                    var status: Int32 = 0
                    while waitpid(child, &status, 0) == -1 && errno == EINTR {}
                    admission.signal()
                }
            }
        }

        let deadline = ProcessInfo.processInfo.systemUptime + timeout
        var diagnostic = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        var eof = false
        while true {
            guard ProcessInfo.processInfo.systemUptime < deadline else {
                throw FileLinkError("The editor launcher timed out. Check tmux and try again.")
            }
            if !eof {
                let count = read(descriptors[0], &buffer, buffer.count)
                if count > 0 {
                    guard diagnostic.count + count <= stderrBytesMax else {
                        throw FileLinkError("The editor launcher exceeded the 16 KiB diagnostic limit.")
                    }
                    diagnostic.append(contentsOf: buffer.prefix(count))
                    continue
                } else if count == 0 {
                    eof = true
                } else if errno != EAGAIN && errno != EINTR {
                    throw systemError("read launcher diagnostics", errno)
                }
            }
            var observation = siginfo_t()
            guard waitid(P_PID, id_t(process), &observation, WEXITED | WNOHANG | WNOWAIT) == 0 else {
                if errno == EINTR { continue }
                throw systemError("observe launcher exit", errno)
            }
            if observation.si_pid != 0 {
                guard observation.si_code == CLD_EXITED && observation.si_status == 0 else {
                    let message = String(decoding: diagnostic, as: UTF8.self)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    throw FileLinkError(message.isEmpty ? "The editor launcher failed." : message)
                }
                return
            }
            var descriptor = pollfd(fd: descriptors[0], events: Int16(POLLIN | POLLHUP), revents: 0)
            if eof { poll(nil, 0, 10) } else { poll(&descriptor, 1, 10) }
        }
    }

    private static func withStrings<T>(_ strings: [String],
        body: (UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>) throws -> T) throws -> T {
        var pointers = strings.map { strdup($0) }
        defer { for pointer in pointers { free(pointer) } }
        guard pointers.allSatisfy({ $0 != nil }) else { throw systemError("allocate launcher arguments", ENOMEM) }
        pointers.append(nil)
        return try pointers.withUnsafeMutableBufferPointer { try body($0.baseAddress!) }
    }

    private static func check(_ result: Int32) throws {
        if result != 0 { throw systemError("start editor launcher", result) }
    }

    private static func systemError(_ operation: String, _ code: Int32) -> FileLinkError {
        FileLinkError("Cannot \(operation): \(String(cString: strerror(code))).")
    }
}
