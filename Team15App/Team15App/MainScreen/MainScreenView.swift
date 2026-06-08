import SwiftUI

// MARK: - Main Screen View

struct MainScreenView: View {
    let ticket:      TicketData
    let preferences: UserPreferences
    let onBack:      () -> Void

    @StateObject private var speech = SpeechService()

    // AI Suggestions
    @State private var suggestions:   [String]   = []
    @State private var isLoadingAI:   Bool       = false

    // Navigation and Sheet State
    @State private var sheetDetent:   PresentationDetent = .fraction(0.5)
    @State private var showTypingInLargeSheet: Bool = false
    @State private var prefillText:   String      = ""

    // Mic animation rings
    @State private var ring1:         CGFloat     = 1.0
    @State private var ring2:         CGFloat     = 1.0
    @State private var ringOpacity1:  Double      = 0.0
    @State private var ringOpacity2:  Double      = 0.0

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
                    // MARK: - Top Bar
                    topBar
                        .padding(.top, 48)
                        .padding(.horizontal, 20)

                    Spacer(minLength: 8)

                    // Transcript or placeholder display
                    contentArea(maxHeight: isCollapsed ? outerGeo.size.height * 0.5 : 110)
                        .padding(.horizontal, 28)

                    Spacer(minLength: 12)

                    // Mic button with rings
                    micSection
                        .padding(.bottom, isCollapsed ? 110 : 8)
                }
                .frame(height: isCollapsed ? outerGeo.size.height : outerGeo.size.height * 0.49)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: .constant(true)) {
            Group {
                if sheetDetent == .large && showTypingInLargeSheet {
                     TextWhileTypingView(
                        initialText:  prefillText,
                        ticket:       ticket,
                        preferences:  preferences,
                        onDismiss: { typedText in
                            speech.transcript = typedText
                            showTypingInLargeSheet = false
                            withAnimation(.spring()) {
                                sheetDetent = .height(80)
                            }
                            prefillText = ""
                        }
                    )
                    .preferredColorScheme(.light)
                } else {
                    suggestionsSheetContent
                        .preferredColorScheme(.light)
                }
            }
            .presentationDetents([.height(80), .fraction(0.5), .large], selection: $sheetDetent)
            .presentationBackgroundInteraction(.enabled)
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(true)
        }
        .task {
            _ = await speech.requestPermissions()
            await loadSuggestions()
        }
        .onChange(of: speech.isListening) { _, listening in
            if listening {
                startRingAnimation()
            } else {
                stopRingAnimation()
            }
        }
        .onChange(of: sheetDetent) { _, newValue in
            if newValue == .fraction(0.5) || newValue == .large {
                if speech.isListening {
                    speech.stopListening()
                }
            }
            if newValue == .fraction(0.5) {
                showTypingInLargeSheet = false
            }
        }
    }

    // MARK: - Suggestions Sheet Content Helper

    @ViewBuilder
    private var suggestionsSheetContent: some View {
        VStack(spacing: 0) {
            Text("Type your thoughts")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.navy)
                .padding(.top, isCollapsed ? 12 : 20)
                .padding(.bottom, isCollapsed ? 12 : 12)

            if !isCollapsed {
                // Type your own button
                Button(action: {
                    prefillText = ""
                    withAnimation(.spring()) {
                        sheetDetent = .large
                        showTypingInLargeSheet = true
                    }
                }) {
                    HStack {
                        Text("Type your own...")
                            .font(.system(size: 15))
                            .foregroundColor(Color(UIColor.placeholderText))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(24)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Suggestions List
                if isLoadingAI {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                } else {
                    VStack(spacing: 8) {
                        ForEach(suggestions.prefix(3), id: \.self) { s in
                            Button(action: {
                                prefillText = s
                                withAnimation(.spring()) {
                                    sheetDetent = .large
                                    showTypingInLargeSheet = true
                                }
                            }) {
                                Text(s)
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.navy)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(AppColors.cardBg)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer().frame(height: 16)

                // See more button
                Button("See more") {
                    prefillText = ""
                    withAnimation(.spring()) {
                        sheetDetent = .large
                        showTypingInLargeSheet = false
                    }
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.navy)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)

                Spacer()
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            BackButton(action: {
                if isCollapsed {
                    withAnimation(.spring()) {
                        sheetDetent = .fraction(0.5)
                    }
                } else {
                    onBack()
                }
            })
            Spacer()
            if !isCollapsed {
                Text(speech.isListening ? "Listening..." : "Start Listening")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.navy)
            }
            Spacer()
            // Balance the back button
            Circle().fill(Color.clear).frame(width: 38, height: 38)
        }
    }

    // MARK: - Content Area (transcript / placeholder)

    @ViewBuilder
    private func contentArea(maxHeight: CGFloat) -> some View {
        if (speech.isListening || isCollapsed) && speech.transcript.isEmpty {
            // Placeholder "I am deaf..." shown during listening or collapsed idle
            VStack(alignment: .leading, spacing: 24) {
                Text("I am deaf, I use\nthis device to\ncommunicate with\nyou.")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(AppColors.navy.opacity(0.25))
                    .lineSpacing(4)

                Text("Say what you\nwant to say to\nme now.")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(AppColors.navy.opacity(0.25))
                    .lineSpacing(4)
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
                .fill(
                    RadialGradient(
                        colors: [AppColors.orange.opacity(0.22), AppColors.orange.opacity(0.0)],
                        center: .center,
                        startRadius: buttonSize * 0.375,
                        endRadius: buttonSize * 0.5
                    )
                )
                .frame(width: buttonSize, height: buttonSize)
                .scaleEffect(ring2)
                .opacity(ringOpacity2)

            // Inner ring (ring 1)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColors.orange.opacity(0.35), AppColors.orange.opacity(0.0)],
                        center: .center,
                        startRadius: buttonSize * 0.3125,
                        endRadius: buttonSize * 0.5
                    )
                )
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

    // MARK: - AI Suggestions

    private func loadSuggestions() async {
        isLoadingAI = true
        suggestions  = await AIService.generateSuggestions(ticket: ticket, preferences: preferences)
        isLoadingAI  = false
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
        preferences: UserPreferences(disability: "Deaf / Hard of Hearing"),
        onBack: {}
    )
}
