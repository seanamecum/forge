import SwiftUI

/// 14-step onboarding. Edits a draft profile, commits to AppState at the end.
struct OnboardingFlowView: View {
    @Environment(AppState.self) private var app
    @State private var step = 0
    @State private var draft = MockData.sean
    @State private var selectedInjuries: Set<InjuryType> = []
    @State private var selectedWearables: Set<String> = []

    private let totalSteps = 14

    var body: some View {
        VStack(spacing: 0) {
            // Progress
            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Theme.card))
                        .frame(height: 3)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            HStack {
                if step > 0 {
                    Button {
                        withAnimation { step -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(Theme.muted)
                    }
                }
                Spacer()
                Text("STEP \(step + 1) OF \(totalSteps)")
                    .font(Theme.eyebrow(10))
                    .kerning(1.6)
                    .foregroundStyle(Theme.faint)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)

            ScrollView(showsIndicators: false) {
                stepContent
                    .padding(24)
                    .id(step)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .opacity))
            }

            Button(step == totalSteps - 1 ? "Enter The Forge" : "Continue") {
                advance()
            }
            .buttonStyle(GoldButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .background(Theme.bg)
        .animation(.easeInOut(duration: 0.25), value: step)
    }

    private func advance() {
        if step == totalSteps - 1 {
            // Commit the real profile AND the declared injuries (which used to be
            // collected here and then silently dropped).
            app.commitOnboarding(profile: draft, injuries: selectedInjuries)
        } else {
            withAnimation { step += 1 }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0: NameStep(draft: $draft)
        case 1: AgeStep(draft: $draft)
        case 2: SexStep(draft: $draft)
        case 3: HeightStep(draft: $draft)
        case 4: WeightStep(draft: $draft)
        case 5: PickerStep(title: "Where are you starting?",
                           subtitle: "So Forge never over- or under-prescribes.",
                           options: FitnessLevel.allCases, selection: $draft.fitnessLevel,
                           detail: { $0.blurb })
        case 6: PickerStep(title: "How active is your week?",
                           subtitle: "Outside the gym — job, walking, sport.",
                           options: ActivityLevel.allCases, selection: $draft.activityLevel,
                           detail: { _ in "" })
        case 7: GoalStep(draft: $draft)
        case 8: ExperienceStep(draft: $draft)
        case 9: InjuryStep(selected: $selectedInjuries)
        case 10: EquipmentStep(draft: $draft)
        case 11: PickerStep(title: "How do you eat?",
                            subtitle: "Filters the food database to your reality.",
                            options: DietPreference.allCases, selection: $draft.diet,
                            detail: { _ in "" })
        case 12: WearableStep(selected: $selectedWearables)
        default: NotificationStep()
        }
    }
}

// MARK: - Step scaffolding

struct StepHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.display(30))
                .foregroundStyle(Theme.cream)
            Text(subtitle)
                .font(.system(size: 13.5))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 22)
    }
}

struct SelectableRow: View {
    let title: String
    var detail: String = ""
    var icon: String? = nil
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(selected ? Theme.gold : Theme.muted)
                        .frame(width: 26)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(selected ? Theme.cream : Theme.creamDim)
                    if !detail.isEmpty {
                        Text(detail).font(.system(size: 11.5)).foregroundStyle(Theme.faint)
                    }
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Theme.gold : Theme.faint.opacity(0.5))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(selected ? Theme.gold.opacity(0.08) : Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(selected ? Theme.gold.opacity(0.5) : Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
