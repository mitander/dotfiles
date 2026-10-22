import Foundation

struct FileRequest {
    let paths: [String]
    let location: String?

    var arguments: [String] {
        if let location = location {
            return ["--at", location, "--"] + paths
        }
        return paths
    }

    init(urls: [URL]) throws {
        guard !urls.isEmpty, urls.count <= 64 else {
            throw FileLinkError("Open between one and 64 local files.")
        }
        var paths: [String] = []
        var location: String?
        for input in urls {
            guard input.absoluteString.utf8.count <= 16384 else {
                throw FileLinkError("A file link must not exceed 16 KiB.")
            }
            let isNavigation = input.scheme == "myran"
            let url = isNavigation ? try Self.navigationFileURL(input) : input
            guard url.isFileURL, url.host == nil || url.host == "" || url.host == "localhost" else {
                throw FileLinkError("Only local file URLs are supported.")
            }
            guard let pathComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let decodedPath = pathComponents.percentEncodedPath.removingPercentEncoding else {
                throw FileLinkError("File paths must contain valid UTF-8.")
            }
            try Self.validatePath(decodedPath)
            var path = decodedPath
            var target = try url.fragment.map(Self.location)
            // A real colon-containing filename wins over suffix interpretation.
            if !isNavigation, target == nil, !FileManager.default.fileExists(atPath: path),
               let colon = path.range(of: ":", options: .backwards) {
                let suffix = String(path[colon.upperBound...])
                let base = String(path[..<colon.lowerBound])
                if FileManager.default.fileExists(atPath: base) {
                    target = try Self.location(suffix)
                    path = base
                }
            }
            paths.append(path)
            if let target = target {
                guard urls.count == 1 else {
                    throw FileLinkError("A line location requires exactly one file.")
                }
                location = target
            }
        }
        guard paths.reduce(0, { $0 + $1.utf8.count }) <= 16384 else {
            throw FileLinkError("The file request exceeds 16 KiB.")
        }
        self.paths = paths
        self.location = location
    }

    private static func navigationFileURL(_ url: URL) throws -> URL {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.host == "open", components.user == nil, components.password == nil,
              components.port == nil, components.path.isEmpty, components.fragment == nil else {
            throw FileLinkError("Use myran://open?path=/absolute/file&line=352&end=596.")
        }
        var values: [String: String] = [:]
        for item in components.queryItems ?? [] {
            guard ["path", "line", "end"].contains(item.name), values[item.name] == nil,
                  let value = item.value else {
                throw FileLinkError("Unknown, repeated, or empty Myran link parameter.")
            }
            values[item.name] = value
        }
        guard let path = values["path"], path.hasPrefix("/"),
              values["end"] == nil || values["line"] != nil else {
            throw FileLinkError("Myran links require an absolute path and a line before an end line.")
        }
        // Validate decoded data before Foundation can sanitize a NUL into literal "%00".
        try validatePath(path)
        var file = URLComponents(url: URL(fileURLWithPath: path), resolvingAgainstBaseURL: false)!
        if let line = values["line"] {
            let range = values["end"].map { line + "-" + $0 } ?? line
            file.fragment = try location(range)
        }
        return file.url!
    }

    private static func validatePath(_ path: String) throws {
        guard path.hasPrefix("/"), path.utf8.count <= 4096,
              !path.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else {
            throw FileLinkError("File paths must be absolute, control-free, and at most 4096 bytes.")
        }
    }

    static func location(_ text: String) throws -> String {
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)
        guard (1...2).contains(parts.count) else {
            throw FileLinkError("Use a line location such as #L352 or #L352-L596.")
        }
        let lines = try parts.map { part -> Int in
            let digits = part.hasPrefix("L") ? part.dropFirst() : part[...]
            guard !digits.isEmpty, digits.utf8.allSatisfy({ (48...57).contains($0) }),
                  let line = Int(digits), (1...1_000_000).contains(line) else {
                throw FileLinkError("Line numbers must be between one and one million.")
            }
            return line
        }
        guard lines.last! >= lines[0] else {
            throw FileLinkError("A line range must end at or after its first line.")
        }
        return lines.map(String.init).joined(separator: "-")
    }
}

struct FileLinkError: LocalizedError {
    let errorDescription: String?

    init(_ message: String) {
        errorDescription = message
    }
}
