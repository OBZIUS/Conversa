import SwiftUI

// MARK: - Main Screen View

struct MainScreenView: View {
    let ticket:      TicketData
    let preferences: UserPreferences

    @StateObject private var speech = SpeechService()

    // Navigation and Sheet State
    @State private var showSuggestionsSheet = false
    @State private var sheetDetent:   PresentationDetent = .fraction(0.5)
    @State private var prefillText:   String      = ""
    @State private var conversationHistory: [String] = []
    @State private var historyVersion: Int = 0

    @Environment(\.dismiss) private var dismiss

    // Mic animation rings
    @State private var ring1:         CGFloat     = 1.0
    @State private var ring2:         CGFloat     = 1.0
    @State private var ringOpacity1:  Double      = 0.0
    @State private var ringOpacity2:  Double      = 0.0
    @State private var breatheScale: CGFloat     = 1.0

    private var isCollapsed: Bool {
        sheetDetent == .height(80)
    }

    var body: some View {
        GeometryReader { outerGeo in
            ZStack(alignment: .top) {

                // MARK: - Background
                LinearGradient(
                    colors: [Color.white, Color(hex: "#E8EAFF")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // MARK: - Top Content
                VStack(spacing: 0) {
                    if !isCollapsed {
                        Text(speech.isListening ? "Listening..." : "Start Listening")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.navy)
                            .padding(.top, 8)
                    }

                    
//                    Spacer()
                    // Transcript or placeholder display
                    contentArea(maxHeight: isCollapsed ? outerGeo.size.height * 0.5 : 110)
                        .padding(.horizontal, 28)
                        .padding(.top, 20)
                    Spacer()
                    // Mic button with rings
                    micSection
                    Spacer()
                }
                .frame(height: isCollapsed ? outerGeo.size.height : outerGeo.size.height * 0.49)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isCollapsed)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.light)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showSuggestionsSheet) {
            SuggestionsSheet(
                ticket: ticket,
                preferences: preferences,
                recentMessages: $conversationHistory,
                historyVersion: $historyVersion,
                sheetDetent: $sheetDetent,
                prefillText: $prefillText,
                onMessageSent: { addToHistory($0, fromUser: true) },
                onDismiss: { typedText in
                    speech.transcript = typedText
                    addToHistory(typedText, fromUser: true)
                    withAnimation(.spring()) {
                        sheetDetent = .height(80)
                    }
                }
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: handleBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(AppColors.navy)
                }
            }
        }
        .task {
            _ = await speech.requestPermissions()
        }
        .onAppear {
            showSuggestionsSheet = true
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                breatheScale = 1.05
            }
        }
        .onChange(of: speech.isListening) { _, listening in
            if listening {
                startRingAnimation()
            } else {
                stopRingAnimation()
                if !speech.transcript.isEmpty {
                    addToHistory(speech.transcript, fromUser: false)
                }
            }
        }
        .onChange(of: sheetDetent) { _, newValue in
            if newValue == .fraction(0.5) || newValue == .large {
                if speech.isListening {
                    speech.stopListening()
                }
            }
        }
    }

    // MARK: - Content Area (transcript / placeholder)

    @ViewBuilder
    private func contentArea(maxHeight: CGFloat) -> some View {
        if (speech.isListening || isCollapsed) && speech.transcript.isEmpty {
            // Placeholder "I am deaf..." shown during listening or collapsed idle
            VStack(alignment: .leading, spacing: 24) {
                Text("I am deaf, I use\nthis device to\ncommunicate with\nyou.")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(AppColors.navy.opacity(0.25))
//                    .lineSpacing(4)

                Text("Say what you\nwant to say to\nme now.")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(AppColors.navy.opacity(0.25))
//                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(.opacity.combined(with: .scale(scale: 0.97)))

        } else if !speech.transcript.isEmpty {
            // Live transcription text — tapping clears it
            ScrollView {
                Text(speech.transcript)
                    .font(.system(size: isCollapsed ? 28 : 22, weight: .bold))
                    .foregroundColor(AppColors.navy)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineSpacing(6)
            }
            .frame(maxHeight: maxHeight)
            .onTapGesture { speech.clearTranscript() }
            .transition(.opacity)
        }
    }

    // MARK: - Mic Section

    private var micSection: some View {
        let buttonSize: CGFloat = isCollapsed ? 100 : 160
        let iconSize: CGFloat = isCollapsed ? 30 : 54

        return ZStack {
            // Outer ring (ring 2)
            Circle()
                .fill(AppColors.orange.opacity(0.15))
                .frame(width: buttonSize, height: buttonSize)
                .scaleEffect(ring2)
                .opacity(ringOpacity2)

            // Inner ring (ring 1)
            Circle()
                .fill(AppColors.orange.opacity(0.25))
                .frame(width: buttonSize, height: buttonSize)
                .scaleEffect(ring1)
                .opacity(ringOpacity1)

            // Mic / Stop button
            Button(action: handleMicTap) {
                ZStack {
                    Circle()
                        .fill(AppColors.orange)
                        .frame(width: buttonSize, height: buttonSize)
                        .shadow(color: AppColors.orange.opacity(0.4), radius: isCollapsed ? 8 : 12, y: isCollapsed ? 4 : 6)

                    Image(systemName: speech.isListening ? "square.fill" : "mic.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                        .foregroundColor(AppColors.navy)
                }
                .scaleEffect(breatheScale)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func handleMicTap() {
        if speech.isListening {
            speech.stopListening()
        } else {
            speech.clearTranscript()
            speech.startListening()
            withAnimation(.spring()) {
                sheetDetent = .height(80)
            }
        }
    }

    private func addToHistory(_ message: String, fromUser: Bool = false) {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let entry = fromUser ? "You: \(trimmed)" : "Them: \(trimmed)"
        if conversationHistory.last?.caseInsensitiveCompare(entry) == .orderedSame { return }
        conversationHistory.append(entry)
        if conversationHistory.count > 10 {
            conversationHistory = Array(conversationHistory.suffix(10))
        }
        historyVersion += 1
    }

    private func handleBack() {
        showSuggestionsSheet = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            dismiss()
        }
    }

    // MARK: - Ring Animations

    private func startRingAnimation() {
        ringOpacity1 = 1
        ringOpacity2 = 1
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            ring1 = 1.65
        }
        withAnimation(.easeInOut(duration: 1.4).delay(0.25).repeatForever(autoreverses: true)) {
            ring2 = 2.2
        }
    }

    private func stopRingAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            ring1 = 1.0
            ring2 = 1.0
            ringOpacity1 = 0
            ringOpacity2 = 0
        }
    }
}

#Preview {
    MainScreenView(
        ticket: TicketData(name: "Aulia Badrulkamal", from: "Jakarta (CGK)",
                           to: "Bali (DPS)", date: "10 June 2026", flightID: "QZ123",
                           time: "12:00", seat: "12E", gate: "18", boardingTime: "11:30"),
        preferences: UserPreferences(disability: "Deaf / Hard of Hearing")
    )
}
