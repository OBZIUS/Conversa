import Vision
import UIKit
import PDFKit

/// Performs on-device OCR using Apple's Vision framework.
/// Supports UIImage and PDF (first page only).
struct OCRService {

    // MARK: - Public API

    static func recognizeText(from image: UIImage) async -> TicketData {
        guard let cgImage = image.cgImage else { return TicketData() }
        let text = await performOCR(on: cgImage)
        return parseTicket(from: text)
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
                continuation.resume(returning: fullText)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    // MARK: - Field Parsing

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
