import Foundation
import NaturalLanguage
import OSLog

// MARK: - On-Device NL Template Suggestion Service

struct NLTemplateService {

    private static let logger = Logger(subsystem: "com.team15.conversa", category: "NLTemplates")

    // MARK: - Template Definition

    private struct Template {
        let raw: String
        let embeddingKey: String
    }

    // MARK: - Template Bank

    private static let templates: [Template] = {
        let rawTemplates: [String] = [
            // --- Greetings / Introductions ---
            "Hi, my name is {name} and I am deaf. I use this app to communicate with you.",
            "Hello, I am {name}. I communicate by typing on this device.",
            "I am {name}, hard of hearing. Please face me when you speak.",

            // --- Boarding / Gates ---
            "I need help finding gate {gate}.",
            "Where is the boarding gate for my flight?",
            "Has boarding started for flight {flight}?",
            "I am on flight {flight}. Which gate should I go to?",
            "Can you guide me to gate {gate} please?",
            "Is gate {gate} far from here?",
            "My flight {flight} has been delayed. Any updates?",
            "I need priority boarding assistance.",

            // --- Luggage ---
            "I need help with my luggage.",
            "Where is the baggage claim area?",
            "My luggage is missing. Who should I talk to?",
            "Can someone help me carry my bags?",

            // --- Food / Drinks ---
            "Can I get a glass of water?",
            "I would like to order food.",
            "Where is the nearest cafe or restaurant?",
            "I have a {meal} dietary restriction. Do you have options?",
            "Is there a water fountain nearby?",

            // --- Restrooms ---
            "Where is the nearest restroom?",
            "Is there an accessible restroom nearby?",
            "Can you point me to the restroom that is wheelchair accessible?",

            // --- Accessibility / Assistance ---
            "I need accessibility assistance please.",
            "I am deaf. Can you write things down for me?",
            "Please look at my screen, I will type what I need.",
            "Do you have a sign language interpreter available?",
            "Can you help me find a staff member?",
            "I need a wheelchair.",
            "Is there a special assistance desk nearby?",
            "I need visual alerts for announcements.",
            "Can you escort me to my gate?",
            "I cannot hear announcements. Please inform me of any changes.",

            // --- Flight Info ---
            "What time does flight {flight} depart?",
            "Has flight {flight} landed?",
            "What time does the flight land?",
            "Is flight {flight} on time?",
            "When is boarding for flight {flight}?",
            "My flight is {flight}, seat {seat}. Am I in the right place?",

            // --- Directions ---
            "How do I get to the departure lounge?",
            "Which way is the terminal?",
            "Where is the information desk?",
            "How do I find the duty-free shop?",

            // --- Emergency / Urgent ---
            "This is an emergency. I need help immediately.",
            "I need to contact my emergency contact.",
            "I lost my passport. Where do I report it?",
            "I feel unwell. Is there a medical station?",

            // --- Transport / Connections ---
            "I have a connecting flight. Where do I go?",
            "Where can I get a taxi?",
            "How do I reach the train station from here?",
            "Is there a shuttle to the city?",

            // --- General Airport ---
            "Where can I charge my phone?",
            "Is there free Wi-Fi here?",
            "Where are the shops?",
            "Can you recommend a quiet place to wait?",
            "What time is it?",

            // --- Thanking / Politeness ---
            "Thank you for your help.",
            "I appreciate your patience.",
            "Thank you for writing that down.",
            "Have a nice day!",
        ]

        return rawTemplates.map { raw in
            Template(raw: raw, embeddingKey: replacePlaceholdersWithGenerics(raw))
        }
    }()

    // MARK: - Placeholder Substitution

    private static func replacePlaceholdersWithGenerics(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "{name}",             with: "traveler")
        result = result.replacingOccurrences(of: "{gate}",             with: "gate")
        result = result.replacingOccurrences(of: "{flight}",           with: "flight")
        result = result.replacingOccurrences(of: "{seat}",             with: "seat")
        result = result.replacingOccurrences(of: "{destination}",      with: "destination")
        result = result.replacingOccurrences(of: "{from}",             with: "departure")
        result = result.replacingOccurrences(of: "{meal}",             with: "meal")
        result = result.replacingOccurrences(of: "{emergency_phone}",  with: "emergency contact")
        result = result.replacingOccurrences(of: "{disability}",       with: "disability")
        return result
    }

    private static func fillTemplate(_ raw: String, ticket: TicketData, preferences: UserPreferences) -> String {
        let rawFirstName = ticket.name.components(separatedBy: " ").first ?? ""
        let firstName = rawFirstName.isEmpty ? "traveler" : rawFirstName
        let meal = preferences.meal.isEmpty || preferences.meal == "No Preference" ? "dietary" : preferences.meal
        let dest = ticket.to.isEmpty ? "my destination" : ticket.to
        let from = ticket.from.isEmpty ? "departure city" : ticket.from
        let emergencyPhone = preferences.emergencyPhone.isEmpty ? "my emergency contact" : preferences.emergencyPhone
        let disability = preferences.disability.isEmpty || preferences.disability == "No Disability"
            ? "deaf or hard of hearing"
            : preferences.disability

        var result = raw
        result = result.replacingOccurrences(of: "{name}",             with: firstName)
        result = result.replacingOccurrences(of: "{gate}",             with: ticket.gate)
        result = result.replacingOccurrences(of: "{flight}",           with: ticket.flightID)
        result = result.replacingOccurrences(of: "{seat}",             with: ticket.seat)
        result = result.replacingOccurrences(of: "{destination}",      with: dest)
        result = result.replacingOccurrences(of: "{from}",             with: from)
        result = result.replacingOccurrences(of: "{meal}",             with: meal)
        result = result.replacingOccurrences(of: "{emergency_phone}",  with: emergencyPhone)
        result = result.replacingOccurrences(of: "{disability}",       with: disability)
        return result
    }

    // MARK: - Context Builder

    private static func buildContext(
        ticket: TicketData,
        preferences: UserPreferences,
        recentMessages: [String]
    ) -> String {
        var parts: [String] = []

        if !ticket.name.isEmpty      { parts.append("traveler named \(ticket.name)") }
        if !ticket.from.isEmpty      { parts.append("flying from \(ticket.from)") }
        if !ticket.to.isEmpty        { parts.append("to \(ticket.to)") }
        if !ticket.flightID.isEmpty  { parts.append("flight \(ticket.flightID)") }
        if !ticket.gate.isEmpty      { parts.append("gate \(ticket.gate)") }
        if !ticket.seat.isEmpty      { parts.append("seat \(ticket.seat)") }
        if !ticket.boardingTime.isEmpty { parts.append("boarding at \(ticket.boardingTime)") }
        if !ticket.date.isEmpty      { parts.append("on \(ticket.date)") }

        let dis = preferences.disability
        if !dis.isEmpty && dis != "No Disability" {
            parts.append("has \(dis)")
        }

        if !preferences.emergencyPhone.isEmpty {
            parts.append("emergency contact \(preferences.emergencyPhone)")
        }

        if !recentMessages.isEmpty {
            parts.append("recent messages:")
            parts.append(contentsOf: recentMessages)
        }

        return parts.joined(separator: ". ")
    }

    // MARK: - Embedding Cache

    private static let lock = NSLock()
    private static var embeddingCache: [[Double]?]?

    private static func getOrComputeVectors() -> [[Double]?] {
        lock.lock()
        defer { lock.unlock() }

        if let cached = embeddingCache {
            logger.debug("Returning cached template vectors — \(cached.count) templates")
            return cached
        }

        logger.info("Computing NL embeddings for \(templates.count) templates...")
        let computeStart = CFAbsoluteTimeGetCurrent()

        guard let embedding = NLEmbedding.sentenceEmbedding(for: .english) else {
            logger.warning("NL embedding model not available for English")
            let empty: [[Double]?] = Array(repeating: nil, count: templates.count)
            embeddingCache = empty
            return empty
        }

        let vectors: [[Double]?] = templates.map { template in
            embedding.vector(for: template.embeddingKey)
        }
        let loadedCount = vectors.compactMap { $0 }.count
        embeddingCache = vectors

        let elapsed = CFAbsoluteTimeGetCurrent() - computeStart
        logger.info("Computed \(loadedCount)/\(templates.count) template embeddings in \(String(format: "%.2f", elapsed))s — cached")

        return vectors
    }

    // MARK: - Public API

    static func generateSuggestions(
        ticket: TicketData,
        preferences: UserPreferences,
        recentMessages: [String] = []
    ) async -> [String]? {
        let context = buildContext(ticket: ticket, preferences: preferences, recentMessages: recentMessages)
        guard !context.isEmpty else {
            logger.warning("NL generateSuggestions — empty context, returning nil")
            return nil
        }

        logger.debug("NL context (\(context.count) chars): \(context, privacy: .private)")

        guard let embedding = NLEmbedding.sentenceEmbedding(for: .english),
              let contextVector = embedding.vector(for: context) else {
            logger.warning("NL generateSuggestions — failed to compute context embedding")
            return nil
        }

        logger.debug("NL context embedding — dimensions: \(contextVector.count)")

        let templateVectors = getOrComputeVectors()

        let scored: [(index: Int, score: Double)] = templates.indices.compactMap { i in
            guard let templateVector = templateVectors[i] else { return nil }
            return (i, cosineSimilarity(contextVector, templateVector))
        }

        guard !scored.isEmpty else {
            logger.warning("NL generateSuggestions — no scorable templates (\(templateVectors.compactMap { $0 }.count) vectors available)")
            return nil
        }

        let top = scored.sorted(by: { $0.score > $1.score }).prefix(5)

        logger.debug("NL top 5 scores: \(top.map { "\(String(format: "%.4f", $0.score))" }, privacy: .public)")
        logger.info("NL generateSuggestions — top match: \"\(templates[top[0].index].raw, privacy: .private)\" score \(String(format: "%.4f", top[0].score))")

        let result = top.map { entry in
            let template = templates[entry.index]
            return fillTemplate(template.raw, ticket: ticket, preferences: preferences)
        }
        logger.info("NL generateSuggestions SUCCESS — \(result.count) suggestions: \(result, privacy: .private)")
        return result
    }

    // MARK: - Cosine Similarity

    private static func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }

        let dotProduct = zip(a, b).reduce(0.0) { $0 + $1.0 * $1.1 }
        let normA = sqrt(a.reduce(0.0) { $0 + $1 * $1 })
        let normB = sqrt(b.reduce(0.0) { $0 + $1 * $1 })

        guard normA > 0, normB > 0 else { return 0 }
        return dotProduct / (normA * normB)
    }
}
