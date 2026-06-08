import SwiftUI

struct TicketInformationView: View {
    @Binding var ticket: TicketData
    let fromSettings: Bool
    let onBack:    () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            AppColors.ticketBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Navigation Bar
                HStack {
                    BackButton(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // MARK: - Title
                        Text("Ticket Information")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(AppColors.navy)

                        Text("Check your ticket information and edit it if there is\nwrong informations")
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.navy.opacity(0.6))
                            .lineSpacing(3)

                        Spacer().frame(height: 8)

                        // MARK: - Ticket Card
                        ticketCard

                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Ticket Card with Scallop Border

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
                    // Name
                    TicketDisplayField(label: "Name", value: $ticket.name, placeholder: "Passenger name")

                    // From / To
                    HStack(spacing: 12) {
                        TicketDisplayField(label: "From", value: $ticket.from, placeholder: "City (Code)")
                        TicketDisplayField(label: "To",   value: $ticket.to,   placeholder: "City (Code)")
                    }

                    // Date / Flight ID
                    HStack(spacing: 12) {
                        TicketDisplayField(label: "Date",      value: $ticket.date,     placeholder: "DD Month YYYY")
                        TicketDisplayField(label: "Flight ID", value: $ticket.flightID, placeholder: "QZ123")
                    }

                    // Time / Boarding Time
                    HStack(spacing: 12) {
                        TicketDisplayField(label: "Time",          value: $ticket.time,         placeholder: "HH:MM")
                        TicketDisplayField(label: "Boarding Time",  value: $ticket.boardingTime, placeholder: "HH:MM")
                    }

                    // Seat / Gate
                    HStack(spacing: 12) {
                        TicketDisplayField(label: "Seat", value: $ticket.seat, placeholder: "12E")
                        TicketDisplayField(label: "Gate", value: $ticket.gate, placeholder: "18")
                    }
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 28)

                // MARK: - Action Buttons
                Button("Confirm") {
                    onConfirm()
                }
                .buttonStyle(PrimaryButtonStyle(foregroundColor: AppColors.navy))
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
    }
}

// MARK: - Editable/ReadOnly Ticket Field

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
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(AppColors.border, lineWidth: 1)
                        .allowsHitTesting(false)
                )
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
        onBack:    {},
        onConfirm: {}
    )
}
