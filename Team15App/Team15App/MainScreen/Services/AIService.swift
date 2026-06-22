import Foundation
import OSLog

// MARK: - Suggestion Source

enum SuggestionSource {
    case cloud
    case onDevice
    case fallback
}

// MARK: - AI Suggestion Orchestrator

struct AIService {

    private static let logger = Logger(subsystem: "com.team15.conversa", category: "AIService")

    // MARK: - Generate Suggestions (Tiered Fallback)

    /// Returns 5 suggestions using the following fallback chain:
    ///   1. Cloud LLM (Groq)
    ///   2. On-device NL template matching
    ///   3. Hardcoded fallback (always succeeds)
    static func generateSuggestions(
        ticket: TicketData,
        preferences: UserPreferences,
        recentMessages: [String] = []
    ) async -> ([String], SuggestionSource) {
        let overallStart = CFAbsoluteTimeGetCurrent()
        logger.info("generateSuggestions — name: \(ticket.name, privacy: .private), flight: \(ticket.flightID, privacy: .public), gate: \(ticket.gate, privacy: .public), history: \(recentMessages.count) msgs")

        // Tier 1: Cloud LLM
        let tier1Start = CFAbsoluteTimeGetCurrent()
        let cloudResult = await CloudSuggestionService.generateSuggestions(
            ticket: ticket, preferences: preferences, recentMessages: recentMessages
        )
        if Task.isCancelled { return (fallback(ticket: ticket, preferences: preferences), .fallback) }
        if let cloud = cloudResult, !cloud.isEmpty {
            let elapsed = CFAbsoluteTimeGetCurrent() - tier1Start
            let totalElapsed = CFAbsoluteTimeGetCurrent() - overallStart
            logger.info("generateSuggestions → TIER 1 (cloud) SUCCESS — \(cloud.count) suggestions in \(String(format: "%.2f", elapsed))s (total: \(String(format: "%.2f", totalElapsed))s)")
            return (cloud, .cloud)
        }
        let tier1Elapsed = CFAbsoluteTimeGetCurrent() - tier1Start
        logger.warning("generateSuggestions → TIER 1 (cloud) FAILED after \(String(format: "%.2f", tier1Elapsed))s")

        // Tier 2: On-device NL template matching
        let tier2Start = CFAbsoluteTimeGetCurrent()
        let nlResult = await NLTemplateService.generateSuggestions(
            ticket: ticket, preferences: preferences, recentMessages: recentMessages
        )
        if Task.isCancelled { return (fallback(ticket: ticket, preferences: preferences), .fallback) }
        if let nl = nlResult, !nl.isEmpty {
            let elapsed = CFAbsoluteTimeGetCurrent() - tier2Start
            let totalElapsed = CFAbsoluteTimeGetCurrent() - overallStart
            logger.info("generateSuggestions → TIER 2 (on-device) SUCCESS — \(nl.count) suggestions in \(String(format: "%.2f", elapsed))s (total: \(String(format: "%.2f", totalElapsed))s)")
            return (nl, .onDevice)
        }
        let tier2Elapsed = CFAbsoluteTimeGetCurrent() - tier2Start
        logger.warning("generateSuggestions → TIER 2 (on-device) FAILED after \(String(format: "%.2f", tier2Elapsed))s")

        // Tier 3: Hardcoded fallback
        let fallbackResult = fallback(ticket: ticket, preferences: preferences)
        let totalElapsed = CFAbsoluteTimeGetCurrent() - overallStart
        logger.info("generateSuggestions → TIER 3 (fallback) — \(fallbackResult.count) hardcoded suggestions (total: \(String(format: "%.2f", totalElapsed))s)")
        return (fallbackResult, .fallback)
    }

    // MARK: - Typing Completions (Cloud only)

    static func typingCompletions(
        text: String,
        ticket: TicketData,
        preferences: UserPreferences,
        recentMessages: [String] = []
    ) async -> [String] {
        guard text.count >= 4 else { return [] }
        if Task.isCancelled { return [] }
        return await CloudSuggestionService.typingCompletions(
            text: text, ticket: ticket, preferences: preferences, recentMessages: recentMessages
        )
    }

    // MARK: - Hardcoded Fallback (Tier 3)

    static func fallback(ticket: TicketData, preferences: UserPreferences = UserPreferences()) -> [String] {
        let rawFirstName = ticket.name.components(separatedBy: " ").first ?? ""
        let firstName = rawFirstName.isEmpty ? "Leo" : rawFirstName
        let disability = preferences.disability.isEmpty || preferences.disability == "No Disability"
            ? "deaf or hard of hearing"
            : preferences.disability
        let meal = preferences.meal.isEmpty || preferences.meal == "No Preference"
            ? "dietary restriction"
            : preferences.meal

        var list: [String] = []

        list.append("Hi there, my name is \(firstName) and I am \(disability). I use this app to communicate with you.")

        if !ticket.flightID.isEmpty {
            list.append("I am on flight \(ticket.flightID)\(ticket.gate.isEmpty ? "" : " at gate \(ticket.gate)"). Can you assist me?")
        } else if !ticket.gate.isEmpty {
            list.append("I need help finding gate \(ticket.gate).")
        } else {
            list.append("I need help finding my gate.")
        }

        if !preferences.meal.isEmpty && preferences.meal != "No Preference" {
            list.append("I have a \(meal) dietary restriction. Do you have suitable options?")
        } else {
            list.append("Can you show me on a screen or write it down?")
        }

        if !preferences.disability.isEmpty && preferences.disability != "No Disability" {
            list.append("I have \(disability). I need accessibility assistance please.")
        } else {
            list.append("I need accessibility assistance please.")
        }

        list.append("Where is the nearest accessible restroom?")
        return list
    }
}
