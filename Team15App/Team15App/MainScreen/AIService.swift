import Foundation

// MARK: - Groq AI Service

struct AIService {

    private static var apiKey: String {
        loadAPIKeyFromEnv() ?? ""
    }
    private static let baseURL = "https://api.groq.com/openai/v1/chat/completions"
    private static let model   = "llama-3.3-70b-versatile"

    private static func loadAPIKeyFromEnv() -> String? {
        if let envKey = ProcessInfo.processInfo.environment["GROQ_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil) else {
            return nil
        }
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: "=")
            if parts.count >= 2 {
                let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                if key == "GROQ_API_KEY" {
                    let val = parts[1...].joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)
                    return val.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                }
            }
        }
        return nil
    }

    // MARK: - System Prompt Builder

    static func buildSystemPrompt(ticket: TicketData, preferences: UserPreferences) -> String {
        var prompt = "You are a communication assistant for a deaf or hard-of-hearing person at an airport. "
        prompt += "Your job is to suggest short, natural phrases they can show to airport staff. "
        prompt += "Keep each phrase under 20 words. "

        if !ticket.name.isEmpty      { prompt += "Traveler: \(ticket.name). " }
        if !ticket.from.isEmpty      { prompt += "Flying from \(ticket.from)" }
        if !ticket.to.isEmpty        { prompt += " to \(ticket.to). " }
        if !ticket.flightID.isEmpty  { prompt += "Flight: \(ticket.flightID). " }
        if !ticket.gate.isEmpty      { prompt += "Gate: \(ticket.gate). " }
        if !ticket.seat.isEmpty      { prompt += "Seat: \(ticket.seat). " }
        if !ticket.boardingTime.isEmpty { prompt += "Boarding: \(ticket.boardingTime). " }
        if !ticket.date.isEmpty      { prompt += "Date: \(ticket.date). " }

        let dis = preferences.disability
        if !dis.isEmpty && dis != "No Disability" {
            prompt += "Person has: \(dis). "
        }
        let meal = preferences.meal
        if !meal.isEmpty && meal != "No Preference" {
            prompt += "Meal preference: \(meal). "
        }

        return prompt
    }

    // MARK: - Generate Suggestions (5 phrases)

    static func generateSuggestions(ticket: TicketData, preferences: UserPreferences) async -> [String] {
        let system = buildSystemPrompt(ticket: ticket, preferences: preferences)
        let user   = """
        Generate exactly 5 helpful short phrases for this deaf/hard-of-hearing airport traveler.
        Make them specific to their flight details when available.
        Return ONLY a JSON array of strings. No markdown, no explanation.
        Example: ["phrase 1","phrase 2","phrase 3","phrase 4","phrase 5"]
        """

        guard let raw = await chat(system: system, user: user) else {
            return fallback(ticket: ticket)
        }

        // Try direct JSON decode
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = trimmed.data(using: .utf8),
           let arr  = try? JSONDecoder().decode([String].self, from: data) {
            return arr
        }

        // Extract JSON array from markdown or extra text
        let regex = try? NSRegularExpression(pattern: #"\[[\s\S]*?\]"#)
        let ns = trimmed as NSString
        if let match = regex?.firstMatch(in: trimmed, range: NSRange(location: 0, length: ns.length)) {
            let json = ns.substring(with: match.range)
            if let data = json.data(using: .utf8),
               let arr  = try? JSONDecoder().decode([String].self, from: data) {
                return arr
            }
        }

        return fallback(ticket: ticket)
    }

    // MARK: - Typing Completion (contextual inline suggestions)

    static func typingCompletions(text: String, ticket: TicketData, preferences: UserPreferences) async -> [String] {
        guard text.count >= 3 else { return [] }

        let system = buildSystemPrompt(ticket: ticket, preferences: preferences)
            + "Complete or suggest 3 different short endings for the phrase the user is typing. "
            + "Return ONLY a JSON array of 3 strings."
        let user   = "The user has typed: \"\(text)\". Suggest 3 completions."

        guard let raw = await chat(system: system, user: user) else { return [] }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = trimmed.data(using: .utf8),
           let arr  = try? JSONDecoder().decode([String].self, from: data) {
            return Array(arr.prefix(3))
        }

        let regex = try? NSRegularExpression(pattern: #"\[[\s\S]*?\]"#)
        let ns = trimmed as NSString
        if let match = regex?.firstMatch(in: trimmed, range: NSRange(location: 0, length: ns.length)) {
            let json = ns.substring(with: match.range)
            if let data = json.data(using: .utf8),
               let arr  = try? JSONDecoder().decode([String].self, from: data) {
                return Array(arr.prefix(3))
            }
        }
        return []
    }

    // MARK: - Core HTTP Chat

    static func chat(system: String, user: String) async -> String? {
        guard let url = URL(string: baseURL) else { return nil }

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
            "temperature": 0.7
        ]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        req.httpBody = httpBody

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let first   = choices.first,
               let message = first["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            print("AIService error: \(error.localizedDescription)")
        }
        return nil
    }

    // MARK: - Fallback Suggestions

    static func fallback(ticket: TicketData) -> [String] {
        let firstName = ticket.name.components(separatedBy: " ").first ?? "Leo"
        let name = firstName.isEmpty ? "Leo" : firstName
        var list: [String] = []

        list.append("Hi there, my name is \(name) and I am deaf. I use this app to communicate with you.")
        list.append(ticket.gate.isEmpty
            ? "I need help finding my gate."
            : "I need help finding gate \(ticket.gate).")
        list.append(ticket.flightID.isEmpty
            ? "Can you show me on a screen or write it down?"
            : "I am on flight \(ticket.flightID). Can you assist me?")
        list.append("I need wheelchair/accessibility assistance please.")
        list.append("Where is the nearest accessible restroom?")
        return list
    }
}
