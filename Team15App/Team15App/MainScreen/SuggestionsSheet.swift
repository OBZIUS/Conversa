import SwiftUI
import OSLog

struct SuggestionsSheet: View {
    let ticket: TicketData
    let preferences: UserPreferences
    @Binding var recentMessages: [String]
    @Binding var historyVersion: Int
    @Binding var sheetDetent: PresentationDetent
    @Binding var prefillText: String
    let onMessageSent: (String) -> Void
    let onDismiss: (String) -> Void

    private static let logger = Logger(subsystem: "com.team15.conversa", category: "SuggestionsSheet")

    @State private var typedText: String = ""
    @State private var showFlipText = false
    @State private var showEditor = false
    @FocusState private var fieldFocused: Bool
    @State private var suggestions: [String] = []
    @State private var isLoadingSuggestions = false
    @State private var debounceTask: Task<Void, Never>? = nil
    @State private var refreshTask: Task<Void, Never>? = nil
    @State private var editorSize: CGSize = .zero
    @State private var suggestionSource: SuggestionSource = .fallback
    @State private var completionGeneration: Int = 0

    private let generalSuggestions = [
        "I need help with my luggage.",
        "Where is the boarding gate?",
        "Can I get a glass of water?",
        "I would like to order food.",
        "What time does the flight land?",
    ]

    private var isPeek: Bool {
        sheetDetent == .height(80) || sheetDetent == .fraction(0.1)
    }

    private var isMedium: Bool {
        sheetDetent == .fraction(0.5)
    }

    private var isLarge: Bool {
        sheetDetent == .large
    }

    private var displaySuggestions: [String] {
        let source = suggestions.isEmpty ? generalSuggestions : suggestions
        var seen = Set<String>()
        return source.filter { seen.insert($0).inserted }
    }

    var body: some View {
        Group {
            if isPeek {
                peekContent
            } else if isMedium {
                mediumContent
            } else {
                expandedContent
            }
        }
        .preferredColorScheme(.light)
        .presentationDetents([.height(80), .fraction(0.5), .large], selection: $sheetDetent)
        .presentationBackgroundInteraction(.enabled)
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(true)
        .onAppear {
            typedText = prefillText
            Task { await loadInitialSuggestions() }
        }
        .task(id: historyVersion) {
            guard historyVersion > 0 else { return }
            refreshTask?.cancel()
            refreshTask = Task { await refreshSuggestions() }
        }
        .fullScreenCover(isPresented: $showFlipText) {
            FlipTextView(text: typedText) {
                showFlipText = false
            }
        }
        .onDisappear {
            debounceTask?.cancel()
            refreshTask?.cancel()
        }
    }

    // MARK: - Peek Content

    private var peekContent: some View {
        VStack(spacing: 0) {
            Text("Type your thoughts")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.navy)
                .padding(.top, 12)
        }
    }

    // MARK: - Medium Content

    private var mediumContent: some View {
        VStack(spacing: 0) {
            Text("Type your thoughts")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.navy)
                .padding(.top, 20)
                .padding(.bottom, 12)

            Button {
                withAnimation(.spring()) { sheetDetent = .large }
                showEditor = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { fieldFocused = true }
            } label: {
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

            if isLoadingSuggestions {
                ProgressView()
                    .padding()
            } else {
                HStack(spacing: 4) {
                    if suggestionSource == .cloud {
                        Image(systemName: "wand.and.sparkles")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.navy)
                    }
                    Text("Suggestions")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.subtitle)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 8) {
                    ForEach(Array(displaySuggestions.prefix(3).enumerated()), id: \.offset) { _, s in
                        Button {
                            debounceTask?.cancel()
                            onMessageSent(s)
                            typedText = s
                            withAnimation(.spring()) { sheetDetent = .large }
                            showEditor = true
                        } label: {
                            Text(s)
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.navy)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer().frame(height: 16)

            Button("See more") {
                withAnimation(.spring()) { sheetDetent = .large }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(AppColors.navy)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 20)

            Spacer()
        }
        .background(Color.white.onTapGesture { Keyboard.dismiss() })
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private var expandedContent: some View {
        if showEditor {
            editorContent
        } else {
            compactExpandedContent
        }
    }

    // MARK: - Compact Expanded (large detent, before editor)

    private var compactExpandedContent: some View {
        VStack(spacing: 0) {
            Text("Type your thoughts")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.navy)
                .padding(.top, 16)
                .padding(.bottom, 8)

            Divider()

            Button {
                showEditor = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { fieldFocused = true }
            } label: {
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
            .padding(.top, 16)
            .padding(.bottom, 16)

            if isLoadingSuggestions {
                ProgressView()
                    .padding()
            } else {
                HStack(spacing: 4) {
                    if suggestionSource == .cloud {
                        Image(systemName: "wand.and.sparkles")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.navy)
                    }
                    Text("Suggestions")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.subtitle)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 8) {
                    ForEach(Array(displaySuggestions.enumerated()), id: \.offset) { _, s in
                        Button {
                            debounceTask?.cancel()
                            onMessageSent(s)
                            typedText = s
                            showEditor = true
                        } label: {
                            Text(s)
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.navy)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .background(Color.white.onTapGesture { Keyboard.dismiss() })
    }

    // MARK: - Editor (large detent, after tapping field or suggestion)

    private var editorContent: some View {
        ZStack {
            VStack(spacing: 0) {
                Text("Type your thoughts")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.navy)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                Divider()

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "#EEF0FF"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if typedText.isEmpty {
                        Text("Start typing below...")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppColors.navy.opacity(0.3))
                            .padding(EdgeInsets(top: 20, leading: 16, bottom: 20, trailing: 20))
                            .allowsHitTesting(false)
                    }

                    FittingTextEditor(
                        text: $typedText,
                        focus: $fieldFocused,
                        availableSize: editorSize,
                        contentPadding: 16
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .frame(minHeight: 200, maxHeight: 340)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear { editorSize = geometry.size }
                            .onChange(of: geometry.size) { _, newSize in
                                editorSize = newSize
                            }
                    }
                )
                .onTapGesture { fieldFocused = true }
                .onChange(of: typedText) { _, newValue in
                    triggerSuggestionDebounce(for: newValue)
                }

                HStack(spacing: 0) {
                    Button(action: {
                        typedText = ""
                        showEditor = false
                    }) {
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

                    Button(action: {
                        fieldFocused = false
                        showFlipText = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(UIColor.systemGray5))
                                .frame(width: 44, height: 44)
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(typedText.isEmpty ? AppColors.navy.opacity(0.3) : AppColors.navy)
                        }
                    }
                    .disabled(typedText.isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

                if !suggestions.isEmpty || isLoadingSuggestions {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 4) {
                            if suggestionSource == .cloud {
                                Image(systemName: "wand.and.sparkles")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppColors.navy)
                            }
                            Text("Suggestions")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.subtitle)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)

                        if isLoadingSuggestions {
                            HStack {
                                ProgressView().scaleEffect(0.8)
                                Text("Getting suggestions...")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.subtitle)
                            }
                            .padding(.horizontal, 20)
                        } else {
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(Array(displaySuggestions.enumerated()), id: \.offset) { _, s in
                                        Button {
                                            debounceTask?.cancel()
                                            onMessageSent(s)
                                            typedText = s
                                        } label: {
                                            Text(s)
                                                .font(.system(size: 14))
                                                .foregroundColor(AppColors.navy)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .multilineTextAlignment(.leading)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
//                            .frame(maxHeight: 140)
                        }
                    }
                    .padding(.bottom, 8)
                }

                Spacer()
            }
            .background(Color.white.ignoresSafeArea().onTapGesture { Keyboard.dismiss() })

            VStack {
                HStack {
                    Button(action: {
                        showEditor = false
                        onDismiss(typedText)
                        prefillText = ""
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.navy)
                            .padding(12)
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding(.top, 8)
            .padding(.leading, 8)
        }
    }

    // MARK: - Suggestions

    private func loadInitialSuggestions() async {
        isLoadingSuggestions = true
        Self.logger.debug("loadInitialSuggestions started — history: \(self.recentMessages.count) msgs")
        let result = await AIService.generateSuggestions(ticket: ticket, preferences: preferences, recentMessages: recentMessages)
        suggestions = filterAlreadySpoken(result.0)
        suggestionSource = result.1
        isLoadingSuggestions = false
        Self.logger.info("loadInitialSuggestions completed — \(suggestions.count) suggestions, source: \(String(describing: result.1))")
    }

    private func refreshSuggestions() async {
        Self.logger.debug("refreshSuggestions triggered — historyVersion: \(self.historyVersion), history: \(self.recentMessages.count) msgs")
        debounceTask?.cancel()
        let capturedHistory = historyVersion
        let result = await AIService.generateSuggestions(ticket: ticket, preferences: preferences, recentMessages: recentMessages)
        guard !Task.isCancelled, capturedHistory == historyVersion else {
            Self.logger.debug("refreshSuggestions discarded — historyVersion changed during fetch")
            return
        }
        suggestions = filterAlreadySpoken(result.0)
        suggestionSource = result.1
        Self.logger.info("refreshSuggestions completed — \(suggestions.count) suggestions, source: \(String(describing: result.1))")
    }

    private func triggerSuggestionDebounce(for text: String) {
        debounceTask?.cancel()
        guard text.count >= 4 else { return }
        let generation = completionGeneration + 1
        completionGeneration = generation
        Self.logger.debug("triggerSuggestionDebounce scheduled — gen: \(generation), text: \"\(text)\"")
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled, generation == completionGeneration else {
                Self.logger.debug("triggerSuggestionDebounce cancelled or superseded — gen: \(generation)")
                return
            }
            Self.logger.debug("triggerSuggestionDebounce fetching — gen: \(generation), text: \"\(text)\"")
            let completions = await AIService.typingCompletions(text: text, ticket: ticket, preferences: preferences, recentMessages: recentMessages)
            guard !Task.isCancelled, generation == completionGeneration else {
                Self.logger.debug("triggerSuggestionDebounce result discarded — gen: \(generation)")
                return
            }
            await MainActor.run {
                if !completions.isEmpty {
                    suggestions = filterAlreadySpoken(completions)
                    suggestionSource = .cloud
                    Self.logger.info("triggerSuggestionDebounce — \(completions.count) cloud completions applied")
                } else {
                    Self.logger.debug("triggerSuggestionDebounce — 0 completions returned")
                }
            }
        }
    }

    private func filterAlreadySpoken(_ phrases: [String]) -> [String] {
        let spoken = recentMessages.map { $0.lowercased() }
        return phrases.filter { phrase in
            let p = phrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return !spoken.contains(where: { $0.contains(p) || p.contains($0) })
        }
    }
}

#Preview {
    SuggestionsSheet(
        ticket: TicketData(name: "Aulia", from: "Jakarta (CGK)", to: "Bali (DPS)",
                           date: "10 June 2026", flightID: "QZ123", time: "12:00",
                           seat: "12E", gate: "18", boardingTime: "11:30"),
        preferences: UserPreferences(disability: "Deaf / Hard of Hearing"),
        recentMessages: .constant([]),
        historyVersion: .constant(0),
        sheetDetent: .constant(.large),
        prefillText: .constant("Hi there, I am deaf."),
        onMessageSent: { _ in },
        onDismiss: { _ in }
    )
}
