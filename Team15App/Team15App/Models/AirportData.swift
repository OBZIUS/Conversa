import Foundation

struct Airport: Identifiable, Hashable {
    let id = UUID()
    let city: String
    let code: String
    let country: String

    var display: String { "\(city) (\(code))" }
}

let airports: [Airport] = [
    Airport(city: "Jakarta", code: "CGK", country: "Indonesia"),
    Airport(city: "Bali", code: "DPS", country: "Indonesia"),
    Airport(city: "Surabaya", code: "SUB", country: "Indonesia"),
    Airport(city: "Yogyakarta", code: "YIA", country: "Indonesia"),
    Airport(city: "Medan", code: "KNO", country: "Indonesia"),

    Airport(city: "Singapore", code: "SIN", country: "Singapore"),
    Airport(city: "Kuala Lumpur", code: "KUL", country: "Malaysia"),
    Airport(city: "Bangkok", code: "BKK", country: "Thailand"),
    Airport(city: "Manila", code: "MNL", country: "Philippines"),
    Airport(city: "Ho Chi Minh City", code: "SGN", country: "Vietnam"),
    Airport(city: "Hanoi", code: "HAN", country: "Vietnam"),

    Airport(city: "Tokyo", code: "NRT", country: "Japan"),
    Airport(city: "Tokyo", code: "HND", country: "Japan"),
    Airport(city: "Osaka", code: "KIX", country: "Japan"),
    Airport(city: "Seoul", code: "ICN", country: "South Korea"),
    Airport(city: "Shanghai", code: "PVG", country: "China"),
    Airport(city: "Beijing", code: "PEK", country: "China"),
    Airport(city: "Hong Kong", code: "HKG", country: "Hong Kong"),
    Airport(city: "Taipei", code: "TPE", country: "Taiwan"),

    Airport(city: "Dubai", code: "DXB", country: "UAE"),
    Airport(city: "Doha", code: "DOH", country: "Qatar"),
    Airport(city: "Abu Dhabi", code: "AUH", country: "UAE"),
    Airport(city: "Istanbul", code: "IST", country: "Turkey"),

    Airport(city: "London", code: "LHR", country: "United Kingdom"),
    Airport(city: "Paris", code: "CDG", country: "France"),
    Airport(city: "Amsterdam", code: "AMS", country: "Netherlands"),
    Airport(city: "Frankfurt", code: "FRA", country: "Germany"),
    Airport(city: "Rome", code: "FCO", country: "Italy"),
    Airport(city: "Madrid", code: "MAD", country: "Spain"),

    Airport(city: "New York", code: "JFK", country: "United States"),
    Airport(city: "Los Angeles", code: "LAX", country: "United States"),
    Airport(city: "San Francisco", code: "SFO", country: "United States"),
    Airport(city: "Chicago", code: "ORD", country: "United States"),

    Airport(city: "Sydney", code: "SYD", country: "Australia"),
    Airport(city: "Melbourne", code: "MEL", country: "Australia"),
    Airport(city: "Auckland", code: "AKL", country: "New Zealand"),

    Airport(city: "Delhi", code: "DEL", country: "India"),
    Airport(city: "Mumbai", code: "BOM", country: "India"),
    Airport(city: "Chennai", code: "MAA", country: "India"),
]
