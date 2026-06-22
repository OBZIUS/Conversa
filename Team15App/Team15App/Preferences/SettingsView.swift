import SwiftUI

struct SettingsView: View {
    @Binding var preferences: UserPreferences
    let onEditTicket: () -> Void
    let onReset: () -> Void

    @State private var showContactSheet = false
    @State private var tempCountryCode: String = "+62"
    @State private var tempPhone: String = ""

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            AppColors.ticketBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Title
                        Text("Settings")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(AppColors.navy)
                            .padding(.horizontal, 20)

                        // MARK: - My Ticket Section
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: onEditTicket) {
                                HStack {
                                    Text("My Ticket")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppColors.navy)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Text("Edit")
                                            .font(.system(size: 15))
                                            .foregroundColor(AppColors.navy.opacity(0.6))
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.navy.opacity(0.6))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 18)
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                            }

                            Text("Edit information about your current journey's ticket")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.navy.opacity(0.5))
                                .padding(.leading, 20)
                        }
                        .padding(.horizontal, 20)

                        // MARK: - Preferences Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Preferences")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppColors.navy.opacity(0.5))
                                .padding(.leading, 20)

                            VStack(spacing: 0) {
                                // Row 1: Meal Preferences
                                HStack {
                                    Text("Meal/Dietary Restriction")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppColors.navy)
                                    Spacer()
                                    Menu {
                                        ForEach(mealOptions, id: \.self) { option in
                                            Button(action: { preferences.meal = option }) {
                                                HStack {
                                                    Text(option)
                                                    if preferences.meal == option {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(preferences.meal.isEmpty ? "Edit" : preferences.meal)
                                                .font(.system(size: 15))
                                                .foregroundColor(AppColors.navy.opacity(0.6))
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppColors.navy.opacity(0.4))
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 18)

                                Divider()
                                    .background(AppColors.border.opacity(0.4))
                                    .padding(.horizontal, 20)

                                // Row 2: Seating Position
                                HStack {
                                    Text("Seat Preferences")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppColors.navy)
                                    Spacer()
                                    Menu {
                                        ForEach(seatOptions, id: \.self) { option in
                                            Button(action: { preferences.seat = option }) {
                                                HStack {
                                                    Text(option)
                                                    if preferences.seat == option {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(preferences.seat.isEmpty ? "Edit" : preferences.seat)
                                                .font(.system(size: 15))
                                                .foregroundColor(AppColors.navy.opacity(0.6))
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppColors.navy.opacity(0.4))
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 18)

                                Divider()
                                    .background(AppColors.border.opacity(0.4))
                                    .padding(.horizontal, 20)

                                // Row 3: Emergency Contact
                                HStack {
                                    Text("Emergency Contact")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppColors.navy)
                                    Spacer()
                                    Button(action: {
                                        tempCountryCode = preferences.emergencyCountryCode.isEmpty ? "+62" : preferences.emergencyCountryCode
                                        tempPhone = preferences.emergencyPhone
                                        showContactSheet = true
                                    }) {
                                        HStack(spacing: 4) {
                                            let displayNum = preferences.emergencyPhone.isEmpty ? "Edit" : "\(preferences.emergencyCountryCode) \(preferences.emergencyPhone)"
                                            Text(displayNum)
                                                .font(.system(size: 15))
                                                .foregroundColor(AppColors.navy.opacity(0.6))
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppColors.navy.opacity(0.4))
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 18)

                                Divider()
                                    .background(AppColors.border.opacity(0.4))
                                    .padding(.horizontal, 20)

                                // Row 4: Type of Disability
                                HStack {
                                    Text("Hearing/Speaking Disability")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppColors.navy)
                                    Spacer()
                                    Menu {
                                        ForEach(disabilityOptions, id: \.self) { option in
                                            Button(action: { preferences.disability = option }) {
                                                HStack {
                                                    Text(option)
                                                    if preferences.disability == option {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(preferences.disability.isEmpty ? "Edit" : preferences.disability)
                                                .font(.system(size: 15))
                                                .foregroundColor(AppColors.navy.opacity(0.6))
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppColors.navy.opacity(0.4))
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 18)
                            }
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .sheet(isPresented: $showContactSheet) {
            EmergencyContactEditSheet(
                countryCode: $tempCountryCode,
                phone: $tempPhone,
                onSave: {
                    preferences.emergencyCountryCode = tempCountryCode
                    preferences.emergencyPhone = tempPhone
                    showContactSheet = false
                },
                onDismiss: {
                    showContactSheet = false
                }
            )
            .presentationDetents([.fraction(0.4)])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Emergency Contact Edit Sheet

struct EmergencyContactEditSheet: View {
    @Binding var countryCode: String
    @Binding var phone: String
    let onSave: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#F2F4FF")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header with close button
                HStack {
                    Spacer()
                    Text("Emergency Contact")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.navy)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.navy.opacity(0.4))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Input capsule
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 0) {
                        // Country code dropdown using native Menu
                        Menu {
                            ForEach(countryCodes) { country in
                                Button("\(country.flag) \(country.name) (\(country.code))") {
                                    countryCode = country.code
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(countryCode)
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppColors.subtitle)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                        }

                        Divider()
                            .frame(height: 24)
                            .background(AppColors.border)

                        TextField("Phone number", text: $phone)
                            .keyboardType(.phonePad)
                            .font(.system(size: 15))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                    }
                    .background(Color.white)
                    .cornerRadius(30)

                    Text("Add your emergency contact phone number")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.navy.opacity(0.4))
                        .padding(.leading, 12)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Save button
                Button(action: onSave) {
                    Text("Save")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.navy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(28)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onTapGesture { Keyboard.dismiss() }
    }
}
