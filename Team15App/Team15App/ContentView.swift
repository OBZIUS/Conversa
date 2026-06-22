import SwiftUI

enum SetupRoute: Hashable {
    case preferences
    case uploadTicket
    case ticketInformation
}

enum MainRoute: Hashable {
    case settings
    case uploadTicket
    case ticketInformation(fromSettings: Bool)
    case mainScreen
}

struct ContentView: View {
    @State private var hasCompletedSetup = false
    @State private var preferences = UserPreferences()
    @State private var ticket = TicketData()

    var body: some View {
        Group {
            if !hasCompletedSetup {
                SetupFlow(preferences: $preferences, ticket: $ticket) {
                    hasCompletedSetup = true
                }
                .transition(.opacity)
            } else {
                MainFlow(preferences: $preferences, ticket: $ticket) {
                    hasCompletedSetup = false
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.light)
        .animation(.easeInOut(duration: 0.2), value: hasCompletedSetup)
    }
}

struct SetupFlow: View {
    @Binding var preferences: UserPreferences
    @Binding var ticket: TicketData
    let onComplete: () -> Void

    @State private var path: [SetupRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingView(
                onSkip: { path.append(.preferences) },
                onFinish: { path.append(.preferences) }
            )
            .navigationDestination(for: SetupRoute.self) { route in
                switch route {
                case .preferences:
                    PersonalPreferencesView(
                        onSkip: { path.append(.uploadTicket) },
                        onConfirm: { prefs in
                            preferences = prefs
                            path.append(.uploadTicket)
                        }
                    )

                case .uploadTicket:
                    UploadTicketView { ticketData in
                        ticket = ticketData
                        path.append(.ticketInformation)
                    }

                case .ticketInformation:
                    TicketInformationView(
                        ticket: $ticket,
                        fromSettings: false,
                        onConfirm: {
                            onComplete()
                        }
                    )
                }
            }
        }
    }
}

struct MainFlow: View {
    @Binding var preferences: UserPreferences
    @Binding var ticket: TicketData
    let onReset: () -> Void

    @State private var path: [MainRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                ticket: ticket,
                onSettings: { path.append(.settings) },
                onContinue: { path.append(.mainScreen) },
                onNewJourney: { path.append(.uploadTicket) }
            )
            .navigationDestination(for: MainRoute.self) { route in
                switch route {
                case .settings:
                    SettingsView(
                        preferences: $preferences,
                        onEditTicket: { path.append(.ticketInformation(fromSettings: true)) },
                        onReset: onReset
                    )

                case .uploadTicket:
                    UploadTicketView { ticketData in
                        ticket = ticketData
                        path.append(.ticketInformation(fromSettings: false))
                    }

                case .ticketInformation(let fromSettings):
                    TicketInformationView(
                        ticket: $ticket,
                        fromSettings: fromSettings,
                        onConfirm: {
                            if fromSettings {
                                path.removeLast()
                            } else {
                                path = []
                            }
                        }
                    )

                case .mainScreen:
                    MainScreenView(
                        ticket: ticket,
                        preferences: preferences
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
