import Foundation
import OSLog

// MARK: - Cloud LLM Suggestion Service (Groq)

struct CloudSuggestionService {

    private static let logger = Logger(subsystem: "com.team15.conversa", category: "CloudSuggestions")

    private static var apiKey: String {
        loadAPIKeyFromEnv() ?? ""
    }
    private static let baseURL = "https://api.groq.com/openai/v1/chat/completions"
    private static let model   = "openai/gpt-oss-120b"

    // MARK: - API Key Loading

    private static func loadAPIKeyFromEnv() -> String? {
        if let envKey = ProcessInfo.processInfo.environment["GROQ_API_KEY"], !envKey.isEmpty {
            logger.debug("API key loaded from environment variable")
            return envKey
        }
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil) else {
            logger.warning("No API key: .env file not found in bundle")
            return nil
        }
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            logger.warning("No API key: .env file unreadable at \(path)")
            return nil
        }
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: "=")
            if parts.count >= 2 {
                let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                if key == "GROQ_API_KEY" {
                    let val = parts[1...].joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)
                    let apiKey = val.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                    logger.debug("API key loaded from .env file (length: \(apiKey.count))")
                    return apiKey
                }
            }
        }
        logger.warning("No API key: GROQ_API_KEY not found in .env file")
        return nil
    }

    // MARK: - System Prompt Builder

    static func buildSystemPrompt(
        ticket: TicketData,
        preferences: UserPreferences,
        recentMessages: [String] = []
    ) -> String {
        var parts: [String] = []

        parts.append("You are a communication assistant for a deaf or hard-of-hearing person at an airport.")
        parts.append("Your job is to suggest short, natural phrases they can show to airport staff.")
        parts.append("Keep each phrase under 20 words. Use simple, direct language.")

        var details: [String] = []
        if !ticket.name.isEmpty                  { details.append("Traveler: \(ticket.name)") }
        if !ticket.from.isEmpty && !ticket.to.isEmpty {
            details.append("Route: \(ticket.from) → \(ticket.to)")
        } else if !ticket.from.isEmpty {
            details.append("Departure: \(ticket.from)")
        } else if !ticket.to.isEmpty {
            details.append("Destination: \(ticket.to)")
        }
        if !ticket.flightID.isEmpty              { details.append("Flight: \(ticket.flightID)") }
        if !ticket.gate.isEmpty                  { details.append("Gate: \(ticket.gate)") }
        if !ticket.seat.isEmpty                  { details.append("Seat: \(ticket.seat)") }
        if !ticket.boardingTime.isEmpty          { details.append("Boarding: \(ticket.boardingTime)") }
        if !ticket.date.isEmpty                  { details.append("Date: \(ticket.date)") }

        let dis = preferences.disability
        if !dis.isEmpty && dis != "No Disability" {
            details.append("Condition: \(dis)")
        }

        let meal = preferences.meal
        if !meal.isEmpty && meal != "No Preference" {
            details.append("Dietary: \(meal)")
        }

        if !preferences.emergencyPhone.isEmpty {
            details.append("Emergency contact: \(preferences.emergencyPhone)")
        }

        if !details.isEmpty {
            parts.append("User details: " + details.joined(separator: "; ") + ".")
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Generate Suggestions (cloud)

    static func generateSuggestions(
        ticket: TicketData,
        preferences: UserPreferences,
        recentMessages: [String] = []
    ) async -> [String]? {
        let system = buildSystemPrompt(
            ticket: ticket, preferences: preferences
        )
        var user = ""

        if !recentMessages.isEmpty {
            let last = recentMessages.last ?? ""
            user += "Conversation so far:\n" + recentMessages.joined(separator: "\n") + "\n\n"
            if last.hasPrefix("Them:") || last.hasPrefix("Staff:") {
                user += "The last message was from \"Them\" — they are expecting a response. Suggest exactly 5 short phrases this person can type now. Be conversational.\n\n"
            } else {
                user += "The last message was from \"You\". Suggest exactly 5 short follow-up phrases.\n\n"
            }
        } else {
            user += "Suggest exactly 5 helpful short phrases this person can show to airport staff.\n\n"
        }
        user += """
        Rules:
        - Respond to what the other person just said or asked — don't re-ask questions already answered in the conversation
        - If the other person was helpful, include a natural thank-you or acknowledgment
        - Never suggest a phrase that "You" already said above
        - Each phrase under 20 words, natural and direct
        - Use double quotes, no trailing commas, no markdown
        - Output ONLY a JSON array of 5 strings and nothing else
        """
        
        logger.info("Cloud generateSuggestions — model: \(self.model, privacy: .public), name: \(ticket.name, privacy: .private), flight: \(ticket.flightID, privacy: .public), gate: \(ticket.gate, privacy: .public), history: \(recentMessages.count) msgs, systemLen: \(system.count), userLen: \(user.count)")
        logger.debug("Cloud system prompt: \(system, privacy: .private)")
        logger.debug("Cloud user prompt: \(user, privacy: .public)")

        let start = CFAbsoluteTimeGetCurrent()
        guard let raw = await chat(system: system, user: user) else {
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            logger.warning("Cloud generateSuggestions FAILED — elapsed: \(String(format: "%.2f", elapsed))s")
            return nil
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start
        logger.debug("Cloud raw response (\(raw.count) chars, \(String(format: "%.2f", elapsed))s): \(raw, privacy: .private)")

        if let result = parseJSONArray(from: raw) {
            logger.info("Cloud generateSuggestions SUCCESS — \(result.count) suggestions in \(String(format: "%.2f", elapsed))s: \(result, privacy: .private)")
            return result
        }

        logger.warning("Cloud generateSuggestions — JSON parse failed. Raw: \(raw.prefix(200), privacy: .private)")
        return nil
    }

    // MARK: - Typing Completion (cloud)

    static func typingCompletions(
        text: String,
        ticket: TicketData,
        preferences: UserPreferences,
        recentMessages: [String] = []
    ) async -> [String] {
        guard text.count >= 4 else { return [] }

        let system = buildSystemPrompt(
            ticket: ticket, preferences: preferences
        )
            + " Complete or suggest 3 different ways to finish the phrase the user is typing. Return the full completed sentences as a JSON array."
            + " Your entire response must be a valid JSON array of 3 strings and nothing else. Use double quotes, no trailing commas, no markdown."

        var user = ""
        if !recentMessages.isEmpty {
            user += "Conversation so far:\n" + recentMessages.joined(separator: "\n") + "\n\n"
        }
        user += "The user started typing: \"\(text)\". Complete this phrase in 3 different ways. Never suggest something \"You\" already said in the conversation above. Output ONLY a JSON array of 3 strings."
        
        logger.info("Cloud typingCompletions — text: \"\(text, privacy: .private)\", history: \(recentMessages.count) msgs")

        guard let raw = await chat(system: system, user: user) else {
            logger.warning("Cloud typingCompletions FAILED")
            return []
        }

        logger.debug("Cloud typingCompletions raw: \(raw.prefix(300), privacy: .private)")

        let result = parseJSONArray(from: raw) ?? []
        logger.info("Cloud typingCompletions — \(result.count) completions: \(result, privacy: .private)")
        return result
    }

    // MARK: - Core HTTP Chat

    private static func chat(system: String, user: String) async -> String? {
        guard let url = URL(string: baseURL) else {
            logger.error("Invalid base URL: \(self.baseURL, privacy: .public)")
            return nil
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)",   forHTTPHeaderField: "Authorization")
        req.setValue("application/json",   forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 15

        let body: [String: Any] = [
            "model":    model,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user",   "content": user]
            ],
            "max_tokens":  500,
            "temperature": 0.3
        ]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            logger.error("Failed to serialize HTTP body")
            return nil
        }
        req.httpBody = httpBody

        logger.debug("HTTP request to \(self.baseURL, privacy: .public) — model: \(self.model, privacy: .public), systemLen: \(system.count), userLen: \(user.count), apiKeyPresent: \(!apiKey.isEmpty)")

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            logger.debug("HTTP response status: \(statusCode)")

            if let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let first   = choices.first,
               let message = first["message"] as? [String: Any],
               let content = message["content"] as? String {
                logger.debug("HTTP response parsed — content length: \(content.count)")
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            if let bodyStr = String(data: data, encoding: .utf8) {
                logger.warning("HTTP response unparseable — status: \(statusCode), body: \(bodyStr.prefix(300), privacy: .private)")
            } else {
                logger.warning("HTTP response unparseable — status: \(statusCode), data: \(data.count) bytes")
            }
        } catch {
            logger.error("HTTP request failed: \(error.localizedDescription, privacy: .public)")
        }
        return nil
    }

    // MARK: - JSON Parsing

    private static func parseJSONArray(from raw: String) -> [String]? {
        var text = raw

        // 1. Strip markdown code fences anywhere in the response
        text = stripCodeFences(text)

        // 2. Greedy JSON array extraction: find first '[' and last ']'
        if let start = text.firstIndex(of: "["),
           let end = text.lastIndex(of: "]"),
           start < end {
            let range = start...end
            var jsonStr = String(text[range])

            // 3. Clean common LLM JSON mistakes
            jsonStr = sanitizeJSON(jsonStr)

            // 4. Try JSONDecoder
            if let arr = decodeViaDecoder(jsonStr) { return arr }

            // 5. Try JSONSerialization (.fragmentsAllowed)
            if let arr = decodeViaSerialization(jsonStr) { return arr }
        }

        // 6. Line-by-line fallback: extract quoted strings or numbered items
        if let arr = extractLines(text) {
            logger.debug("JSON extracted via line fallback — \(arr.count) items")
            return arr
        }

        logger.warning("JSON parse failed — raw: \(raw.prefix(300), privacy: .private)")
        return nil
    }

    // MARK: - Sub-Helpers

    /// Remove ```json ... ``` fences regardless of position in text.
    private static func stripCodeFences(_ text: String) -> String {
        let fenceRegex = try? NSRegularExpression(pattern: #"```(?:json)?\s*\n([\s\S]*?)```"#)
        let ns = text as NSString
        if let match = fenceRegex?.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
           match.numberOfRanges >= 2 {
            let inner = ns.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
            if !inner.isEmpty { return inner }
        }
        return text
    }

    /// Remove trailing commas and other minor JSON syntax errors.
    private static func sanitizeJSON(_ json: String) -> String {
        var cleaned = json
        // Remove trailing commas before ] or }
        if let regex = try? NSRegularExpression(pattern: #",\s*([\]}])"#) {
            cleaned = regex.stringByReplacingMatches(in: cleaned, range: NSRange(location: 0, length: (cleaned as NSString).length), withTemplate: "$1")
        }
        // Fix single quotes → double quotes (only around strings, not nested)
        // Simple heuristic: replace leading/trailing single quotes of array elements
        if let regex = try? NSRegularExpression(pattern: #"'(?=[^']*'[,\]\s])"#) {
            // Too risky for general case; skip aggressive quote normalization
        }
        return cleaned
    }

    private static func decodeViaDecoder(_ json: String) -> [String]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }

    private static func decodeViaSerialization(_ json: String) -> [String]? {
        guard let data = json.data(using: .utf8) else { return nil }
        if let obj = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) {
            if let arr = obj as? [String], !arr.isEmpty { return arr }
            if let arr = obj as? [Any] {
                return arr.compactMap { ($0 as? String) ?? "\($0)" }
            }
            if let str = obj as? String { return [str] }
        }
        return nil
    }

    /// Extract phrases from numbered lists, bullet points, or bare quoted strings.
    private static func extractLines(_ text: String) -> [String]? {
        let lines = text.components(separatedBy: .newlines)
        var results: [String] = []

        let numberPattern = try? NSRegularExpression(pattern: #"^\s*\d+[\.\)]\s*(.+)$"#)
        let bulletPattern = try? NSRegularExpression(pattern: #"^\s*[-•*]\s*(.+)$"#)
        let quotePattern  = try? NSRegularExpression(pattern: #""([^"]+)""#)

        for line in lines {
            let ns = line as NSString

            // Try numbered: "1. phrase text"
            if let m = numberPattern?.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)),
               m.numberOfRanges >= 2 {
                let phrase = ns.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespaces)
                if !phrase.isEmpty { results.append(phrase) }
                continue
            }

            // Try bullet: "- phrase text"
            if let m = bulletPattern?.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)),
               m.numberOfRanges >= 2 {
                let phrase = ns.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespaces)
                if !phrase.isEmpty { results.append(phrase) }
                continue
            }
        }

        // If no numbered/bulleted items found, try extracting all quoted strings
        if results.isEmpty {
            if let matches = quotePattern?.matches(in: text, range: NSRange(location: 0, length: (text as NSString).length)) {
                for match in matches where match.numberOfRanges >= 2 {
                    let phrase = (text as NSString).substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
                    if !phrase.isEmpty { results.append(phrase) }
                }
            }
        }

        return results.isEmpty ? nil : Array(results.prefix(5))
    }
}
