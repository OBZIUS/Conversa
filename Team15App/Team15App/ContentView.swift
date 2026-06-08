import SwiftUI

// MARK: - App Route Enum

enum AppRoute: Equatable {
    case onboarding
    case preferences
    case uploadTicket
    case ticketInformation(fromSettings: Bool)
    case home
    case mainScreen
    case settings
}

// MARK: - Root Content View

struct ContentView: View {
    @State private var route:       AppRoute     = .onboarding
    @State private var preferences: UserPreferences = UserPreferences()
    @State private var ticket:      TicketData   = TicketData()

    var body: some View {
        Group {
            switch route {
            case .onboarding:
                OnboardingView(
                    onSkip:   { route = .preferences },
                    onFinish: { route = .preferences }
                )
                .transition(.opacity)

            case .preferences:
                PersonalPreferencesView(
                    onBack: { route = .onboarding },
                    onSkip: { route = .uploadTicket },
                    onConfirm: { prefs in
                        preferences = prefs
                        route = .uploadTicket
                    }
                )
                .transition(.opacity)

            case .uploadTicket:
                UploadTicketView(
                    onBack: { route = .preferences },
                    onNext: { ticketData in
                        ticket = ticketData
                        route = .ticketInformation(fromSettings: false)
                    }
                )
                .transition(.opacity)

            case .ticketInformation(let fromSettings):
                TicketInformationView(
                    ticket: $ticket,
                    fromSettings: fromSettings,
                    onBack:    { 
                        if fromSettings {
                            route = .settings
                        } else {
                            route = .uploadTicket 
                        }
                    },
                    onConfirm: {
                        if fromSettings {
                            route = .settings
                        } else {
                            route = .home
                        }
                    }
                )
                .transition(.opacity)

            case .home:
                HomeView(
                    ticket: ticket,
                    onSettings: { route = .settings },
                    onContinue: { route = .mainScreen },
                    onNewJourney: { route = .uploadTicket }
                )
                .transition(.opacity)

            case .mainScreen:
                MainScreenView(
                    ticket:      ticket,
                    preferences: preferences,
                    onBack:      { route = .home }
                )
                .transition(.opacity)

            case .settings:
                SettingsView(
                    preferences: $preferences,
                    onBack: { route = .home },
                    onEditTicket: { route = .ticketInformation(fromSettings: true) }
                )
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.light)
        .animation(.easeInOut(duration: 0.2), value: String(describing: route))
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
