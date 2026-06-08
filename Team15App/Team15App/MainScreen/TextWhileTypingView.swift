import SwiftUI

// MARK: - TextWhileTypingView

struct TextWhileTypingView: View {
    let initialText:  String
    let ticket:       TicketData
    let preferences:  UserPreferences
    let onDismiss:    (String) -> Void

    @State private var typedText:        String = ""
    @State private var isFlipped:        Bool   = false
    @FocusState private var fieldFocused: Bool
    @State private var suggestions:      [String] = []
    @State private var isLoadingSuggestions = false
    @State private var debounceTask:     Task<Void, Never>? = nil

    // Dynamic font size calculation based on text length
    private var dynamicFontSize: CGFloat {
        let length = typedText.count
        if length < 30 {
            return 48
        } else if length < 60 {
            return 36
        } else if length < 120 {
            return 28
        } else if length < 240 {
            return 22
        } else {
            return 18
        }
    }

    var body: some View {
        ZStack {
            // Main Typing Screen Content (shown when NOT flipped)
            VStack(spacing: 0) {
                // MARK: - Title
                Text("Type your thoughts")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.navy)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                Divider()

                // MARK: - Text Display Card
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "#EEF0FF"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if typedText.isEmpty {
                        Text("Start typing below...")
                            .font(.system(size: dynamicFontSize, weight: .bold))
                            .foregroundColor(AppColors.navy.opacity(0.3))
                            .padding(EdgeInsets(top: 20, leading: 16, bottom: 20, trailing: 20))
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $typedText)
                        .font(.system(size: dynamicFontSize, weight: .bold))
                        .foregroundColor(AppColors.navy)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .focused($fieldFocused)
                        .padding(16)
                        .onChange(of: typedText) { _, newValue in
                            triggerSuggestionDebounce(for: newValue)
                        }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .onTapGesture { fieldFocused = true }

                // MARK: - Action Buttons (X and ↕)
                HStack(spacing: 0) {
                    // Clear button
                    Button(action: { typedText = "" }) {
                        ZStack {
                            Circle()
                                .fill(Color(UIColor.systemGray5))
                                .frame(width: 44, height: 44)
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.navy)
                        }
                    }

                    Spacer()

                    // Flip button
                    Button(action: { 
                        fieldFocused = false
                        isFlipped.toggle() 
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(UIColor.systemGray5))
                                .frame(width: 44, height: 44)
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.navy)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

                // MARK: - AI Suggestions
                if !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Suggestions")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.subtitle)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 8) {
                                ForEach(suggestions, id: \.self) { suggestion in
                                    Button(action: { typedText = suggestion }) {
                                        Text(suggestion)
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.navy)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(AppColors.cardBg)
                                            .cornerRadius(10)
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        .frame(maxHeight: 140)
                    }
                    .padding(.bottom, 8)
                } else if isLoadingSuggestions {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Getting suggestions...")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.subtitle)
                    }
                    .padding(.vertical, 8)
                }

                Spacer()
            }
            .background(Color.white.ignoresSafeArea())
            .overlay(alignment: .topLeading) {
                Button(action: { onDismiss(typedText) }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.navy)
                        .padding(12)
                }
                .padding(.top, 8)
                .padding(.leading, 8)
            }

            // MARK: - Flipped Big Screen Mode Overlay
            if isFlipped {
                ZStack {
                    Color.white
                        .ignoresSafeArea()

                    VStack(spacing: 24) {
                        Spacer()

                        // Text rotated 180 degrees so it's readable for the person opposite the user
                        ScrollView {
                            Text(typedText.isEmpty ? "Start typing below..." : typedText)
                                .font(.system(size: min(72, dynamicFontSize * 1.6), weight: .bold))
                                .foregroundColor(AppColors.navy)
                                .multilineTextAlignment(.center)
                                .padding(24)
                                .rotationEffect(.degrees(180))
                                .frame(maxWidth: .infinity)
                        }

                        Spacer()

                        // Action button to unflip
                        Button(action: { 
                            isFlipped = false 
                            fieldFocused = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.up.arrow.down.circle.fill")
                                    .font(.system(size: 20))
                                Text("Flip Back")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(AppColors.navy)
                            .cornerRadius(28)
                            .shadow(color: AppColors.navy.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.bottom, 32)
                    }
                }
                .transition(.asymmetric(insertion: .opacity, removal: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isFlipped)
        .preferredColorScheme(.light)
        .onAppear {
            typedText = initialText
            fieldFocused = true
            Task { await loadInitialSuggestions() }
        }
    }

    // MARK: - Handle View

    private var handle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(UIColor.systemGray4))
            .frame(width: 40, height: 5)
    }

    // MARK: - Suggestion Loading

    private func loadInitialSuggestions() async {
        isLoadingSuggestions = true
        suggestions = await AIService.generateSuggestions(ticket: ticket, preferences: preferences)
        isLoadingSuggestions = false
    }

    private func triggerSuggestionDebounce(for text: String) {
        debounceTask?.cancel()
        guard text.count >= 4 else { return }
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s debounce
            guard !Task.isCancelled else { return }
            let completions = await AIService.typingCompletions(
                text: text, ticket: ticket, preferences: preferences)
            await MainActor.run {
                if !completions.isEmpty { suggestions = completions }
            }
        }
    }
}

#Preview {
    TextWhileTypingView(
        initialText: "Hi there, I am deaf.",
        ticket: TicketData(name: "Aulia", from: "Jakarta (CGK)", to: "Bali (DPS)",
                           date: "10 June 2026", flightID: "QZ123", time: "12:00",
                           seat: "12E", gate: "18", boardingTime: "11:30"),
        preferences: UserPreferences(disability: "Deaf / Hard of Hearing"),
        onDismiss: { _ in }
    )
}
