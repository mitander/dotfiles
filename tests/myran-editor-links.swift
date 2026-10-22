import Foundation

@main
struct FileLinkTests {
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("file ' %20 # & + ; 世界 $(literal).log")
        try Data("text\n".utf8).write(to: file)
        let plain = try FileRequest(urls: [file])
        precondition(plain.arguments == [file.path])

        var components = URLComponents(url: file, resolvingAgainstBaseURL: false)!
        components.fragment = "L352-L596"
        let range = try FileRequest(urls: [components.url!])
        precondition(range.arguments == ["--at", "352-596", "--", file.path])
        var navigation = URLComponents(string: "myran://open")!
        navigation.queryItems = [URLQueryItem(name: "path", value: file.path),
                                 URLQueryItem(name: "line", value: "352"),
                                 URLQueryItem(name: "end", value: "596")]
        let navigated = try FileRequest(urls: [navigation.url!])
        precondition(navigated.arguments == range.arguments)
        components.fragment = "L42"
        let line = try FileRequest(urls: [components.url!])
        precondition(line.arguments == ["--at", "42", "--", file.path])
        let suffix = URL(fileURLWithPath: file.path + ":352-596")
        let suffixed = try FileRequest(urls: [suffix])
        precondition(suffixed.arguments == range.arguments)
        navigation.queryItems = [URLQueryItem(name: "path", value: suffix.path)]
        let missingLiteral = try FileRequest(urls: [navigation.url!])
        precondition(missingLiteral.arguments == [suffix.path])
        try Data("literal suffix\n".utf8).write(to: suffix)
        let literal = try FileRequest(urls: [suffix])
        precondition(literal.arguments == [suffix.path])

        let percentNul = URL(fileURLWithPath: directory.path + "/literal%00name.log")
        let literalPercent = try FileRequest(urls: [percentNul])
        precondition(literalPercent.paths == [percentNul.path])
        navigation.queryItems = [URLQueryItem(name: "path", value: percentNul.path)]
        let navigationPercent = try FileRequest(urls: [navigation.url!])
        precondition(navigationPercent.paths == [percentNul.path])

        let normalized = try FileRequest.location("0001-L0002")
        precondition(normalized == "1-2")
        for invalid in ["", "0", "L0", "2-1", "L352-L0", "1-1000001", "1000001", "1-", "1-2-3", "1|quit", "+1"] {
            do {
                _ = try FileRequest.location(invalid)
                preconditionFailure("Accepted invalid location: \(invalid)")
            } catch is FileLinkError {}
        }
        let invalidRequests = [
            [], [URL(string: "https://example.com")!],
            [URL(string: "file://remote/tmp/a.log")!],
            [URL(fileURLWithPath: "/tmp/control\n.log")],
            [URL(string: "file:///tmp/a%00suffix")!],
            [URL(string: "file:///tmp/a%FFsuffix")!],
            [URL(string: "myran://open?path=/tmp/a%00suffix")!],
            [URL(string: "myran://open?path=/tmp/a%0Asuffix")!],
            [URL(string: "myran://open?path=/tmp/a&line=" + String(repeating: "0", count: 16384))!],
            [URL(fileURLWithPath: "/" + String(repeating: "x", count: 4096))],
            Array(repeating: URL(fileURLWithPath: "/" + String(repeating: "x", count: 4095)), count: 5),
            [components.url!, file],
            [URL(string: "myran://open?path=relative&line=1")!],
            [URL(string: "myran://open?path=/tmp/a&line=1&line=2")!],
            [URL(string: "myran://open?path=/tmp/a&end=2")!],
            [URL(string: "myran://open?path=/tmp/a&command=quit")!],
            [URL(string: "myran://remote?path=/tmp/a&line=1")!],
            [URL(string: "myran://user@open?path=/tmp/a&line=1")!],
            Array(repeating: file, count: 65),
        ]
        for urls in invalidRequests {
            do {
                _ = try FileRequest(urls: urls)
                preconditionFailure("Accepted invalid file request: \(urls)")
            } catch is FileLinkError {}
        }
        print("PASS: literal file URLs, fragments, ranges, existing suffix filenames, bounded local input")
    }
}
