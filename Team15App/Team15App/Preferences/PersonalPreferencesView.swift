import SwiftUI

// MARK: - Country Code Model

struct CountryCode: Identifiable {
    let id = UUID()
    let flag: String
    let code: String
    let name: String
}

let countryCodes: [CountryCode] = [
    CountryCode(flag: "🇦🇺", code: "+61", name: "Australia"),
    CountryCode(flag: "🇧🇷", code: "+55", name: "Brazil"),
    CountryCode(flag: "🇨🇦", code: "+1",  name: "Canada"),
    CountryCode(flag: "🇨🇳", code: "+86", name: "China"),
    CountryCode(flag: "🇫🇷", code: "+33", name: "France"),
    CountryCode(flag: "🇩🇪", code: "+49", name: "Germany"),
    CountryCode(flag: "🇮🇳", code: "+91", name: "India"),
    CountryCode(flag: "🇮🇩", code: "+62", name: "Indonesia"),
    CountryCode(flag: "🇯🇵", code: "+81", name: "Japan"),
    CountryCode(flag: "🇲🇾", code: "+60", name: "Malaysia"),
    CountryCode(flag: "🇸🇬", code: "+65", name: "Singapore"),
    CountryCode(flag: "🇰🇷", code: "+82", name: "South Korea"),
    CountryCode(flag: "🇬🇧", code: "+44", name: "United Kingdom"),
    CountryCode(flag: "🇺🇸", code: "+1",  name: "United States"),
]

// MARK: - Options

let mealOptions = [
    "No Preference",
    "Vegan",
    "Vegetarian",
    "Halal",
    "Kosher",
    "Gluten-Free"
]

let seatOptions = [
    "No Preference",
    "Window Seat",
    "Aisle Seat",
    "Middle Seat",
    "Extra Legroom"
]

let disabilityOptions = [
    "No Disability",
    "Deaf",
    "Hard of Hearing",
    "Mute / Non-verbal",
    "Speech Impairment",
    "Deaf and Mute"
]

// MARK: - View

struct PersonalPreferencesView: View {
    let onSkip: () -> Void
    let onConfirm: (UserPreferences) -> Void

    @State private var mealPreference: String = ""
    @State private var seatPreference: String = ""
    @State private var selectedCountry: CountryCode = countryCodes[7] // Indonesia +62
    @State private var emergencyPhone: String = ""
    @State private var disability: String = ""
    @State private var showCountryPicker = false

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            AppColors.ticketBg
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Set Preferences")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(AppColors.navy)

                        Text("This preferences will make your suggestion\nsmoother thoughout the journey!")
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.navy.opacity(0.6))
                            .lineSpacing(3)
                    }

                    .padding(.top, 16)
                    .padding(.horizontal, 32)

                    Spacer().frame(height: 24)

                    // MARK: - Scalloped Card
                    ScallopedCard {
                        VStack(spacing: 0) {
                            Text("Personal Preferences")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundColor(AppColors.navy)
                                .padding(.top, 28)
                                .padding(.bottom, 12)

                            DashDivider()
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)

                            VStack(spacing: 18) {
                                // Meal
                                FormPickerRow(
                                    label: "Meal/Dietary Restriction",
                                    placeholder: "eg. Vegan",
                                    options: mealOptions,
                                    selection: $mealPreference
                                )

                                // Seat
                                FormPickerRow(
                                    label: "Seat Preferences",
                                    placeholder: "eg. Window Seat",
                                    options: seatOptions,
                                    selection: $seatPreference
                                )

                                // Emergency Contact
                                VStack(alignment: .leading, spacing: 6) {
                                    FormFieldLabel(text: "Emergency Contact")
                                    HStack(spacing: 0) {
                                        // Country code selector using native Menu
                                        Menu {
                                            ForEach(countryCodes) { country in
                                                Button("\(country.flag) \(country.name) (\(country.code))") {
                                                    selectedCountry = country
                                                }
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                Text(selectedCountry.flag)
                                                    .font(.system(size: 16))
                                                Text(selectedCountry.code)
                                                    .font(.system(size: 15))
                                                    .foregroundColor(.primary)
                                                Image(systemName: "chevron.down")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(AppColors.subtitle)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 13)
                                            .background(Color.clear)
                                        }

                                        Divider()
                                            .frame(height: 24)
                                            .background(AppColors.border)

                                        TextField("Phone number", text: $emergencyPhone)
                                            .keyboardType(.phonePad)
                                            .font(.system(size: 15))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 13)
                                    }
                                    .background(AppColors.fieldBg)
                                    .cornerRadius(30)
                                }

                                // Disability
                                FormPickerRow(
                                    label: "Hearing/Speaking Disability",
                                    placeholder: "eg. Deaf, Hard of Hearing, etc",
                                    options: disabilityOptions,
                                    selection: $disability
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            Spacer().frame(height: 24)

                            // MARK: - Confirm Button
                            Button("Confirm") {
                                let prefs = UserPreferences(
                                    meal: mealPreference,
                                    seat: seatPreference,
                                    emergencyPhone: emergencyPhone,
                                    emergencyCountryCode: selectedCountry.code,
                                    disability: disability
                                )
                                onConfirm(prefs)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal, 20)
                            .padding(.bottom, 28)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }

            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        onSkip()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.navy)
                }
            }
        }
        .onTapGesture { Keyboard.dismiss() }
    }
}

// MARK: - Rounded Corner Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    PersonalPreferencesView(onSkip: {}, onConfirm: { _ in })
}
