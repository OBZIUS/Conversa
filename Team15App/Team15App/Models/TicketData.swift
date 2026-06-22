import Foundation

/// Holds all ticket information extracted by OCR.
/// Fields are optional — nil means OCR could not extract that field.
struct TicketData: Equatable {
    var name: String = ""
    var from: String = ""
    var to: String = ""
    var date: String = ""
    var flightID: String = ""
    var time: String = ""
    var seat: String = ""
    var gate: String = ""
    var boardingTime: String = ""
    var wasAIParsed: Bool = false

    /// Returns true if every field is empty (OCR produced no useful data)
    var isEmpty: Bool {
        return name.isEmpty && from.isEmpty && to.isEmpty &&
               date.isEmpty && flightID.isEmpty && time.isEmpty &&
               seat.isEmpty && gate.isEmpty && boardingTime.isEmpty
    }
}
