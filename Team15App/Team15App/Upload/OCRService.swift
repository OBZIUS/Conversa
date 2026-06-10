import Vision
import UIKit
import PDFKit
import OSLog

/// Performs on-device OCR using Apple's Vision framework.
/// Supports UIImage and PDF (first page only).
/// Uses cloud AI (Groq) for intelligent field parsing when available,
/// falling back to rules-based parsing.
struct OCRService {

    // MARK: - Cloud AI Configuration

    private static let logger = Logger(subsystem: "com.team15.conversa", category: "OCRService")
    private static let groqBaseURL = "https://api.groq.com/openai/v1/chat/completions"
    private static let groqModel   = "openai/gpt-oss-120b"

    private static var groqAPIKey: String? {
        if let envKey = ProcessInfo.processInfo.environment["GROQ_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        for line in content.components(separatedBy: .newlines) {
            let parts = line.components(separatedBy: "=")
            if parts.count >= 2,
               parts[0].trimmingCharacters(in: .whitespacesAndNewlines) == "GROQ_API_KEY" {
                return parts[1...].joined(separator: "=")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            }
        }
        return nil
    }

    // MARK: - Public API

    static func recognizeText(from image: UIImage) async -> TicketData {
        guard let cgImage = image.cgImage else {
            logger.warning("No CGImage from UIImage, returning empty TicketData")
            return TicketData()
        }
        let text = await performOCR(on: cgImage)
        logger.debug("Vision OCR completed — \(text.count) chars extracted")

        guard groqAPIKey != nil else {
            logger.info("No Groq API key — using rules-based parser")
            let result = parseTicket(from: text)
            logger.debug("Rules-based parse result: name=\(result.name), flight=\(result.flightID), from=\(result.from), to=\(result.to)")
            return result
        }

        logger.info("Attempting cloud AI parsing...")
        if let cloudResult = await parseTicketWithAI(from: text) {
            return cloudResult
        }

        logger.info("Cloud parsing failed or timed out — falling back to rules-based parser")
        let result = parseTicket(from: text)
        logger.debug("Rules-based fallback result: name=\(result.name), flight=\(result.flightID), from=\(result.from), to=\(result.to)")
        return result
    }

    static func recognizeText(fromPDF url: URL) async -> TicketData {
        guard let document = PDFDocument(url: url),
              let page = document.page(at: 0) else { return TicketData() }

        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)
            ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
        return await recognizeText(from: image)
    }

    // MARK: - Vision OCR

    private static func performOCR(on cgImage: CGImage) async -> String {
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { req, _ in
                let observations = req.results as? [VNRecognizedTextObservation] ?? []
                let fullText = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                logger.debug("Vision OCR completed — \(observations.count) text blocks, \(fullText.count) chars total")
                continuation.resume(returning: fullText)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    // MARK: - Cloud AI Field Parsing

    /// Sends raw OCR text to Groq LLM for intelligent field extraction.
    /// Returns nil if cloud is unavailable, times out, or parsing fails.
    static func parseTicketWithAI(from rawText: String) async -> TicketData? {
        guard let apiKey = groqAPIKey, !apiKey.isEmpty else { return nil }

        let systemPrompt = """
        You are a flight ticket data extractor. Extract structured fields from OCR text of a boarding pass or ticket.

        Return ONLY a JSON object with these keys (use "" if not found):
        - "name": passenger full name
        - "from": departure city or airport code (origin), e.g. "Jakarta (CGK)"
        - "to": arrival city or airport code (destination), e.g. "Bali (DPS)"
        - "date": flight date in its original text format
        - "flightID": flight number like "QZ123", "GA456"
        - "time": departure time (when the flight leaves)
        - "seat": seat number like "12E"
        - "gate": boarding gate number like "18"
        - "boardingTime": boarding time (when boarding starts, earlier than departure)

        IMPORTANT:
        - "from" is the ORIGIN city, NOT phrases like "depart from gate"
        - "to" is the DESTINATION city, NOT phrases like "go to counter"
        - "time" = departure time, "boardingTime" = when boarding starts
        - Do not invent values absent from the text
        - Output ONLY JSON, no markdown, no explanation
        """

        guard let url = URL(string: groqBaseURL) else {
            logger.error("Invalid Groq base URL")
            return nil
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 8

        let body: [String: Any] = [
            "model": groqModel,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user",   "content": rawText]
            ],
            "max_tokens": 500,
            "temperature": 0.0
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            logger.error("Failed to serialize OCR cloud request body")
            return nil
        }
        req.httpBody = httpBody

        logger.info("Cloud OCR parsing — text length: \(rawText.count), model: \(self.groqModel, privacy: .public)")
        logger.debug("Cloud OCR raw text:\n\(rawText, privacy: .private)")

        let start = CFAbsoluteTimeGetCurrent()
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            logger.debug("Cloud OCR response — status: \(statusCode), elapsed: \(String(format: "%.2f", elapsed))s, data: \(data.count) bytes")

            guard (200...299).contains(statusCode) else {
                let bodyStr = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                logger.warning("Cloud OCR HTTP \(statusCode) — body: \(bodyStr.prefix(300), privacy: .private)")
                return nil
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let first = choices.first,
                  let message = first["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                if let bodyStr = String(data: data, encoding: .utf8) {
                    logger.warning("Cloud OCR unparseable response — body: \(bodyStr.prefix(300), privacy: .private)")
                }
                return nil
            }

            logger.debug("Cloud OCR LLM response text: \(content.prefix(500), privacy: .private)")

            if let result = parseCloudJSON(content) {
                logger.info("Cloud OCR SUCCESS — name: \(result.name, privacy: .private), flight: \(result.flightID, privacy: .public), from: \(result.from, privacy: .private), to: \(result.to, privacy: .private), seat: \(result.seat, privacy: .private), gate: \(result.gate, privacy: .public) in \(String(format: "%.2f", elapsed))s")
                return result
            }
            logger.warning("Cloud OCR JSON parse failed — content: \(content.prefix(300), privacy: .private)")
        } catch {
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            logger.warning("Cloud OCR request failed after \(String(format: "%.2f", elapsed))s: \(error.localizedDescription, privacy: .public)")
        }

        return nil
    }

    /// Parses the LLM JSON response into a TicketData struct.
    private static func parseCloudJSON(_ raw: String) -> TicketData? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        let fenceRegex = try? NSRegularExpression(pattern: #"```(?:json)?\s*\n([\s\S]*?)```"#)
        let ns = text as NSString
        if let match = fenceRegex?.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
           match.numberOfRanges >= 2 {
            let inner = ns.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
            if !inner.isEmpty { text = inner }
        }

        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}"),
           start < end {
            text = String(text[start...end])
        }

        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logger.debug("parseCloudJSON: failed to parse — text: \(text.prefix(200), privacy: .private)")

            // Attempt truncated JSON recovery: close unclosed braces
            let openBraces = text.filter { $0 == "{" }.count
            let closeBraces = text.filter { $0 == "}" }.count
            if openBraces > closeBraces {
                let fixed = text + String(repeating: "}", count: openBraces - closeBraces)
                if let fixedData = fixed.data(using: .utf8),
                   let recovered = try? JSONSerialization.jsonObject(with: fixedData, options: .fragmentsAllowed) as? [String: Any] {
                    logger.info("parseCloudJSON: recovered \(recovered.count) keys from truncated JSON")
                    let ticket = buildTicket(from: recovered)
                    return ticket.isEmpty ? nil : ticket
                }
                logger.debug("parseCloudJSON: truncated recovery also failed")
            }
            return nil
        }

        logger.debug("parseCloudJSON: successfully parsed JSON with \(json.count) keys: \(json.keys.sorted(), privacy: .private)")

        let ticket = buildTicket(from: json)
        return ticket.isEmpty ? nil : ticket
    }

    private static func buildTicket(from json: [String: Any]) -> TicketData {
        func str(_ key: String) -> String {
            (json[key] as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
        }

        var ticket = TicketData()
        ticket.name         = str("name")
        ticket.from         = str("from")
        ticket.to           = str("to")
        ticket.date         = str("date")
        ticket.flightID     = str("flightID")
        ticket.time         = str("time")
        ticket.seat         = str("seat")
        ticket.gate         = str("gate")
        ticket.boardingTime = str("boardingTime")
        return ticket
    }

    // MARK: - Rule-Based Field Parsing (Fallback)

    /// Attempts to extract structured ticket fields from raw OCR text.
    static func parseTicket(from text: String) -> TicketData {
        var data = TicketData()
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }

        // Helper: find value after a label keyword
        func value(after keyword: String, in lines: [String]) -> String? {
            for (i, line) in lines.enumerated() {
                let lower = line.lowercased()
                if lower.contains(keyword.lowercased()) {
                    // try same line after colon
                    if let colonRange = line.range(of: ":") {
                        let val = String(line[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                        if !val.isEmpty { return val }
                    }
                    // try next non-empty line
                    if i + 1 < lines.count {
                        let next = lines[i + 1]
                        if !next.isEmpty { return next }
                    }
                }
            }
            return nil
        }

        // Name
        data.name = value(after: "passenger", in: lines)
            ?? value(after: "name", in: lines)
            ?? ""

        // From / To — look for airport codes e.g. CGK or city names
        if let fromLine = value(after: "from", in: lines) {
            data.from = fromLine
        }
        if let toLine = value(after: "to", in: lines) {
            data.to = toLine
        }

        // Date
        if let dateLine = value(after: "date", in: lines) {
            data.date = dateLine
        } else {
            // regex for common date formats dd/MM/yyyy, dd-MM-yyyy, dd Month yyyy
            let dateRegex = try? NSRegularExpression(
                pattern: #"\b(\d{1,2}[\s\-\/]\w+[\s\-\/]\d{2,4}|\d{1,2}\/\d{1,2}\/\d{2,4})\b"#)
            let joined = lines.joined(separator: " ")
            if let match = dateRegex?.firstMatch(in: joined, range: NSRange(joined.startIndex..., in: joined)),
               let range = Range(match.range, in: joined) {
                data.date = String(joined[range])
            }
        }

        // Flight ID — e.g. QZ123, GA456
        let flightRegex = try? NSRegularExpression(pattern: #"\b[A-Z]{1,3}\d{2,4}\b"#)
        let fullText = lines.joined(separator: " ")
        if let match = flightRegex?.firstMatch(in: fullText, range: NSRange(fullText.startIndex..., in: fullText)),
           let range = Range(match.range, in: fullText) {
            data.flightID = String(fullText[range])
        }

        // Departure Time
        let timeRegex = try? NSRegularExpression(pattern: #"\b(\d{1,2}:\d{2})\b"#)
        var timeMatches: [String] = []
        if let matches = timeRegex?.matches(in: fullText, range: NSRange(fullText.startIndex..., in: fullText)) {
            timeMatches = matches.compactMap { Range($0.range, in: fullText).map { String(fullText[$0]) } }
        }
        data.time = timeMatches.first ?? value(after: "depart", in: lines) ?? ""

        // Boarding Time — second time match or label
        data.boardingTime = value(after: "boarding", in: lines)
            ?? value(after: "board", in: lines)
            ?? (timeMatches.count > 1 ? timeMatches[1] : "")

        // Seat
        data.seat = value(after: "seat", in: lines) ?? ""

        // Gate
        data.gate = value(after: "gate", in: lines) ?? ""

        return data
    }
}
