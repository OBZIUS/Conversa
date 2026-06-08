import Foundation

struct OnboardingPage: Identifiable {
    let id: Int
    let imageName: String
    let title: String
    let subtitle: String
}

extension OnboardingPage {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            imageName: "onb1",
            title: "Understand every\nconversation",
            subtitle: "Turn spoken words into text instanly.\nYou can follow every conversations with ease\nduring your journey"
        ),
        OnboardingPage(
            id: 1,
            imageName: "onb2",
            title: "Express yourself with ease",
            subtitle: "Respond faster with smart suggestions tailored to your travel needs"
        ),
        OnboardingPage(
            id: 2,
            imageName: "onb3",
            title: "Travel with confidence",
            subtitle: "From check-in counter to cabin crew interaction, enjoy smoother and faster conversations throughout your journey"
        ),
    ]
}
