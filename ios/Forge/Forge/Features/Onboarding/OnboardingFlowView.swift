import SwiftUI

/// 14-step onboarding. Starts from a truly blank account (never the demo athlete),
/// gates Continue only where a real value is required, persists progress so an
/// interrupted run resumes exactly where it left off, and commits at the end.
struct OnboardingFlowView: View {
    @Environment(AppState.self) private var app
    @State private var step = 0
    @State private var draft = UserProfile.blank
    @State private var selectedInjuries: Set<InjuryType> = []
    @State private var selectedWearables: Set<String> = []
    @State private var restored = false
    @State private var showWelcome = true

    private let totalSteps = 15

    /// Continue is enabled only when the current step's required value is real.
    private var canAdvance: Bool {
        switch step {
        case 0: return OnboardingValidation.nameValid(draft)
        case 1: return OnboardingValidation.ageValid(draft)
        case 3: return OnboardingValidation.heightValid(draft)
        case 4: return OnboardingValidation.weightValid(draft)
        case 7: return OnboardingValidation.goalsValid(draft)
        case 10: return OnboardingValidation.equipmentValid(draft)
        default: return true   // sex, activity, experience, injuries, diet, wearable, notifications
        }
    }

    private func persist() {
        OnboardingStore.save(OnboardingProgress(
            step: step, profile: draft,
            injuries: Array(selectedInjuries), wearables: Array(selectedWearables)))
    }

    var body: some View {
        Group {
            if showWelcome {
                WelcomeIntro(onStart: beginSteps).transition(.opacity)
            } else {
                steppedFlow
            }
        }
        .background(Theme.bg)
        .onAppear(perform: restoreIfNeeded)
    }

    private func beginSteps() {
        Haptics.tap()
        withAnimation(Motion.spring) { showWelcome = false }
    }

    private var steppedFlow: some View {
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
            .disabled(!canAdvance)
            .opacity(canAdvance ? 1 : 0.45)
            .animation(Motion.snappy, value: canAdvance)
            .padding(.horizontal, Space.xxl)
            .padding(.bottom, 28)
        }
        .animation(.easeInOut(duration: 0.25), value: step)
        .onChange(of: step) { _, s in
            persist()
            Analytics.log(.onboardingStepViewed, ["step": "\(s)"])
        }
    }

    /// Resume an interrupted run, or start fresh — logged either way.
    private func restoreIfNeeded() {
        guard !restored else { return }
        restored = true
        if let p = OnboardingStore.load() {
            draft = p.profile
            step = min(max(0, p.step), totalSteps - 1)
            selectedInjuries = Set(p.injuries)
            selectedWearables = Set(p.wearables)
            showWelcome = false          // resume straight into the flow, not the intro
            Analytics.log(.onboardingResumed, ["step": "\(step)"])
        } else {
            Analytics.log(.onboardingStarted)
            persist()
        }
    }

    private func advance() {
        guard canAdvance else { return }
        Haptics.tap()
        Analytics.log(.onboardingStepCompleted, ["step": "\(step)"])
        // Leaving the wearable step without connecting is a valid, tracked choice.
        if step == 12, app.healthKit.authState != .authorized {
            Analytics.log(.onboardingWearableSkipped)
        }
        if step == totalSteps - 1 {
            Analytics.log(.onboardingCompleted)
            // Commit the real profile AND declared injuries; finishOnboarding clears
            // the saved progress so the flow never resurfaces.
            app.commitOnboarding(profile: draft, injuries: selectedInjuries)
        } else {
            withAnimation(Motion.spring) { step += 1 }
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
        case 13: NotificationStep()
        default: PlanStep(draft: draft)
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
