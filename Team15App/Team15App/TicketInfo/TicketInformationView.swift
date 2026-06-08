import SwiftUI

struct TicketInformationView: View {
    @Binding var ticket: TicketData
    let fromSettings: Bool
    let onConfirm: () -> Void

    @State private var departureDate = Date()
    @State private var departureTimeDate = Date()
    @State private var boardingTimeDateObj = Date()
    @State private var selectedCityField: CityField? = nil
    @State private var citySearchQuery = ""

    enum CityField: Identifiable {
        case from, to
        var id: Self { self }
    }

    private var filteredAirports: [Airport] {
        if citySearchQuery.isEmpty {
            return airports
        }
        let query = citySearchQuery.lowercased()
        return airports.filter {
            $0.city.lowercased().contains(query) ||
            $0.code.lowercased().contains(query) ||
            $0.country.lowercased().contains(query)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.ticketBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ticket Information")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(AppColors.navy)
                            .padding(.top, 16)

                        Text("Check your ticket information and edit it if there is\nwrong informations")
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.navy.opacity(0.6))
                            .lineSpacing(3)

                        Spacer().frame(height: 8)

                        ticketCard

                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .onTapGesture { Keyboard.dismiss() }
        .onAppear(perform: parseTicketDates)
        .sheet(item: $selectedCityField) { field in
            cityPickerSheet(for: field)
        }
    }

    // MARK: - Ticket Card

    private var ticketCard: some View {
        ScallopedCard {
            VStack(spacing: 0) {
                Text("Your Ticket")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(AppColors.navy)
                    .padding(.top, 28)
                    .padding(.bottom, 12)

                DashDivider()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                VStack(spacing: 14) {
                    TicketDisplayField(label: "Name", value: $ticket.name, placeholder: "Passenger name")

                    HStack(spacing: 12) {
                        cityField(label: "From", value: $ticket.from, field: .from)
                        cityField(label: "To", value: $ticket.to, field: .to)
                    }

                    HStack(spacing: 12) {
                        TicketDisplayField(label: "Flight ID", value: $ticket.flightID, placeholder: "QZ123")
                        timePickerField(
                            label: "Boarding Time",
                            selection: timeBinding(keyPath: \.boardingTime, stateDate: $boardingTimeDateObj)
                        )
                        
                    }

                    HStack(spacing: 12) {
                        datePickerField
                        timePickerField(
                            label: "Departure Time",
                            selection: timeBinding(keyPath: \.boardingTime, stateDate: $departureTimeDate)
                        )
                        
                    }

                    HStack(spacing: 12) {
                        TicketDisplayField(label: "Seat", value: $ticket.seat, placeholder: "12E")
                        TicketDisplayField(label: "Gate", value: $ticket.gate, placeholder: "18")
                    }
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 28)

                Button("Confirm") {
                    onConfirm()
                }
                .buttonStyle(PrimaryButtonStyle(foregroundColor: AppColors.navy))
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
//        .cornerRadius(0)   
    }

    // MARK: - Date Picker Field

    private var datePickerField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Date")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.navy.opacity(0.5))
                .padding(.leading, 8)

            DatePicker(
                "",
                selection: dateBinding,
                displayedComponents: .date
            )
            .labelsHidden()
            .foregroundStyle(AppColors.navy)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.fieldBg)
            .cornerRadius(30)
        }
    }

    // MARK: - Time Picker Field

    private func timePickerField(label: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.navy.opacity(0.5))
                .padding(.leading, 8)

            DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .foregroundStyle(AppColors.navy)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.fieldBg)
                .cornerRadius(30)
        }
    }

    // MARK: - City Picker Field

    private func cityField(label: String, value: Binding<String>, field: CityField) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.navy.opacity(0.5))
                .padding(.leading, 8)

            Button {
                selectedCityField = field
            } label: {
                HStack {
                    Text(value.wrappedValue.isEmpty ? "City (Code)" : value.wrappedValue)
                        .font(.system(size: 15))
                        .foregroundColor(value.wrappedValue.isEmpty ? Color(UIColor.placeholderText) : AppColors.navy)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.subtitle)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(AppColors.fieldBg)
                .cornerRadius(30)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - City Picker Sheet

    private func cityPickerSheet(for field: CityField) -> some View {
        NavigationStack {
            List(filteredAirports) { airport in
                Button {
                    switch field {
                    case .from: ticket.from = airport.display
                    case .to: ticket.to = airport.display
                    }
                    selectedCityField = nil
                    citySearchQuery = ""
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(airport.display)
                            .foregroundColor(AppColors.navy)
                        Text(airport.country)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .searchable(
                text: $citySearchQuery,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search city or airport code"
            )
            .navigationTitle(field == .from ? "Departure City" : "Arrival City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        selectedCityField = nil
                        citySearchQuery = ""
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Bindings

    private var dateBinding: Binding<Date> {
        Binding<Date>(
            get: { departureDate },
            set: { newDate in
                departureDate = newDate
                ticket.date = formatDate(newDate)
            }
        )
    }

    private func timeBinding(keyPath: WritableKeyPath<TicketData, String>, stateDate: Binding<Date>) -> Binding<Date> {
        Binding<Date>(
            get: { stateDate.wrappedValue },
            set: { newDate in
                stateDate.wrappedValue = newDate
                ticket[keyPath: keyPath] = formatTime(newDate)
            }
        )
    }

    // MARK: - Date Helpers

    private func parseTicketDates() {
        let dateFormats = ["d MMMM yyyy", "dd MMMM yyyy", "MMMM d, yyyy", "yyyy-MM-dd"]
        for format in dateFormats {
            let df = DateFormatter()
            df.dateFormat = format
            df.locale = Locale(identifier: "en_US_POSIX")
            if let parsed = df.date(from: ticket.date) {
                departureDate = parsed
                break
            }
        }

        if let parsed = parseTime(ticket.time) {
            departureTimeDate = parsed
        }
        if let parsed = parseTime(ticket.boardingTime) {
            boardingTimeDateObj = parsed
        }
    }

    private func parseTime(_ string: String) -> Date? {
        guard !string.isEmpty else { return nil }
        let formats = ["HH:mm", "h:mm a", "HHmm"]
        for format in formats {
            let df = DateFormatter()
            df.dateFormat = format
            df.locale = Locale(identifier: "en_US_POSIX")
            if let parsed = df.date(from: string) {
                return parsed
            }
        }
        return nil
    }

    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "d MMMM yyyy"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df.string(from: date)
    }
}

// MARK: - Editable Ticket Field (kept for text-based fields)

struct TicketDisplayField: View {
    let label: String
    @Binding var value: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.navy.opacity(0.5))
                .padding(.leading, 8)

            TextField(placeholder.isEmpty ? label : placeholder, text: $value)
                .font(.system(size: 15))
                .foregroundColor(AppColors.navy)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(AppColors.fieldBg)
                .cornerRadius(30)
        }
    }
}

#Preview {
    TicketInformationView(
        ticket: .constant(TicketData(
            name: "Aulia Badrulkamal", from: "Jakarta (CGK)", to: "Bali (DPS)",
            date: "10 June 2026", flightID: "QZ123", time: "12:00",
            seat: "12E", gate: "18", boardingTime: "11:30"
        )),
        fromSettings: false,
        onConfirm: {}
    )
}
