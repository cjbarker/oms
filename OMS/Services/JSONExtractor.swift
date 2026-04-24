import Foundation

/// Strips markdown code fences from LLM output so JSONDecoder can swallow the payload.
enum JSONExtractor {
    static func extract(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("```") {
            // Drop opening fence and optional language tag
            if let firstNewline = s.firstIndex(of: "\n") {
                s = String(s[s.index(after: firstNewline)...])
            }
            // Drop closing fence
            if let range = s.range(of: "```", options: .backwards) {
                s = String(s[..<range.lowerBound])
            }
        }
        // Tolerant fallback: if we see a JSON object, return from its first brace to its last.
        if let start = s.firstIndex(where: { $0 == "{" || $0 == "[" }),
           let end = s.lastIndex(where: { $0 == "}" || $0 == "]" }),
           start <= end {
            return String(s[start...end])
        }
        return s
    }
}
