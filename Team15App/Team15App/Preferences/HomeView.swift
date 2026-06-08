import SwiftUI

struct HomeView: View {
    let ticket: TicketData
    let onSettings: () -> Void
    let onContinue: () -> Void
    let onNewJourney: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            AppColors.ticketBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Navigation Bar
                HStack {
                    Text("Home")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(AppColors.navy)
                    Spacer()
                    Button(action: onSettings) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.navy)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 74)
                .padding(.top, 21)

                

                // MARK: - Main Stamp/Ticket Illustration Card
                VStack(spacing: 20) {
                    Image("home")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 320, height: 320)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)

                    // MARK: - Departure & Arrival Cities
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("from")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppColors.navy.opacity(0.4))
                            Text(ticket.from.isEmpty ? "NA" : ticket.from)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppColors.navy)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("to")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppColors.navy.opacity(0.4))
                            Text(ticket.to.isEmpty ? "NA" : ticket.to)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppColors.navy)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.horizontal, 24)

                Spacer()

                // MARK: - Actions
                VStack(spacing: 12) {
                    Button(action: onContinue) {
                        Text("Continue journey")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppColors.navy)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppColors.orange)
                            .cornerRadius(28)
                    }

                    Button(action: onNewJourney) {
                        Text("New journey")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppColors.navy)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "#E8EBF8"))
                            .cornerRadius(28)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    HomeView(
        ticket: TicketData(from: "Jakarta", to: "Japan"),
        onSettings: {},
        onContinue: {},
        onNewJourney: {}
    )
}
