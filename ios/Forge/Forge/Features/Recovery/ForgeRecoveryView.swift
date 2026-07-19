import SwiftUI

/// Forge Recovery — injury profile, pain tracking, PT library, protocols,
/// return-to-sport, concussion module, and the risk model.
struct ForgeRecoveryView: View {
    @Environment(AppState.self) private var app
    @State private var tab: Tab = .profile

    enum Tab: String, CaseIterable {
        case profile = "Profile"
        case pt = "PT Library"
        case protocols = "Protocols"
        case concussion = "Concussion"
        case rts = "Return"
    }

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Forge Recovery", title: "Injury & PT",
                          subtitle: "Most apps go quiet when you get hurt. Forge starts a protocol and walks you back.")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Tab.allCases, id: \.self) { t in
                        CategoryPill(label: t.rawValue, selected: tab == t) { tab = t }
                    }
                }
            }

            switch tab {
            case .profile: InjuryProfileSection()
            case .pt: PTLibrarySection()
            case .protocols: ProtocolsSection()
            case .concussion: ConcussionSection()
            case .rts: ReturnToSportSection()
            }

            DisclaimerNote()
        }
        .navigationTitle("Forge Recovery")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Profile

struct InjuryProfileSection: View {
    @Environment(AppState.self) private var app
    @State private var painSlider: Double = Double(MockData.knee.painToday)

    var body: some View {
        VStack(spacing: 12) {
            riskCard

            ForEach(app.injuries.active) { injury in
                Card(gold: true) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                EyebrowLabel(text: "\(injury.type.rawValue) · Day \(injury.daysOld)")
                                Text(injury.name).font(Theme.display(20)).foregroundStyle(Theme.cream)
                            }
                            Spacer()
                            Chip(text: injury.phase.rawValue, tone: .amber)
                        }

                        Text(injury.notes).font(.system(size: 12)).foregroundStyle(Theme.creamDim)

                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("Pain today").font(.system(size: 12)).foregroundStyle(Theme.muted)
                                Spacer()
                                Text("\(Int(painSlider)) / 10")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(painSlider >= 5 ? Theme.rubyBright : Theme.amber)
                            }
                            Slider(value: $painSlider, in: 0...10, step: 1) { editing in
                                if !editing { app.injuries.logPain(Int(painSlider), for: injury) }
                            }
                            .tint(painSlider >= 5 ? Theme.ruby : Theme.amber)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("PAIN TREND · 12 DAYS").font(Theme.eyebrow(8)).kerning(1.4).foregroundStyle(Theme.faint)
                            Sparkline(values: injury.painHistory, color: Theme.amber, height: 30)
                        }

                        HStack(spacing: 12) {
                            recoverySubscore("Mobility", injury.mobilityPct)
                            recoverySubscore("Strength", injury.strengthPct)
                            recoverySubscore("Stability", injury.stabilityPct)
                        }
                    }
                }
            }

            addInjuryCard
        }
    }

    private var riskCard: some View {
        let risk = app.injuries.risk
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    ScoreRing(value: risk.percent, label: "Risk", size: 86, lineWidth: 8, tone: .ruby)
                    VStack(alignment: .leading, spacing: 3) {
                        EyebrowLabel(text: "Injury Risk · \(risk.band)")
                        Text("Illustrative risk model").font(Theme.display(17)).foregroundStyle(Theme.cream)
                    }
                    Spacer()
                    Chip(text: "Sample", tone: .amber)
                }
                Text("Sample factors below — an illustration of the model, not a medical prediction about you.")
                    .font(.system(size: 10.5)).foregroundStyle(Theme.faint)
                ForEach(risk.drivers) { d in
                    HStack {
                        Text(d.name).font(.system(size: 11.5)).foregroundStyle(Theme.creamDim)
                        Spacer()
                        Text(d.value).font(.system(size: 11.5, weight: .semibold)).foregroundStyle(Theme.amber)
                    }
                    .padding(.vertical, 2)
                }
                CoachNote(text: risk.recommendation)
            }
        }
    }

    private var addInjuryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                EyebrowLabel(text: "Log a New Injury")
                Text("Forge auto-blocks aggravating lifts and queues the matching protocol.")
                    .font(.system(size: 12)).foregroundStyle(Theme.muted)
                FlowChips(options: InjuryType.allCases.map(\.rawValue),
                          isSelected: { _ in false }, toggle: { _ in })
            }
        }
    }

    private func recoverySubscore(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 3) {
            Text("\(value)%")
                .font(Theme.display(17))
                .foregroundStyle(value >= 80 ? Theme.green : Theme.amber)
            Text(label.uppercased())
                .font(.system(size: 8, weight: .semibold)).kerning(1)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.bgElevated))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.hairline, lineWidth: 1))
    }
}

// MARK: - PT Library

struct PTLibrarySection: View {
    @Environment(AppState.self) private var app

    var body: some View {
        VStack(spacing: 10) {
            ForEach(app.injuries.ptLibrary) { pt in
                Card {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pt.area.uppercased())
                                    .font(.system(size: 8.5, weight: .semibold)).kerning(1.2)
                                    .foregroundStyle(Theme.gold)
                                Text(pt.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.cream)
                            }
                            Spacer()
                            Chip(text: pt.phase.rawValue)
                        }
                        Text(pt.prescription).font(.system(size: 12.5, weight: .medium)).foregroundStyle(Theme.creamDim)
                        Text(pt.note).font(.system(size: 11)).foregroundStyle(Theme.muted)
                    }
                }
            }
        }
    }
}

// MARK: - Protocols

struct ProtocolsSection: View {
    @Environment(AppState.self) private var app

    var body: some View {
        VStack(spacing: 12) {
            ForEach(app.injuries.protocols) { proto in
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(proto.title).font(Theme.display(18)).foregroundStyle(Theme.cream)

                        protoList("Symptoms", proto.symptoms, tone: .amber, symbol: "circle.fill")
                        protoList("What to Avoid", proto.avoid, tone: .ruby, symbol: "xmark")

                        VStack(alignment: .leading, spacing: 7) {
                            EyebrowLabel(text: "Progression Phases")
                            ForEach(proto.phases) { phase in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(phase.name).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(Theme.gold)
                                    Text(phase.goal).font(.system(size: 12)).foregroundStyle(Theme.cream)
                                    Text(phase.criteria).font(.system(size: 11)).foregroundStyle(Theme.muted)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.bgElevated))
                            }
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            EyebrowLabel(text: "Prescribed PT", tone: .green)
                            FlowChips(options: proto.ptExerciseNames, isSelected: { _ in false }, toggle: { _ in })
                        }
                    }
                }
            }
        }
    }

    private func protoList(_ title: String, _ items: [String], tone: Tone, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            EyebrowLabel(text: title, tone: tone)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 7) {
                    Image(systemName: symbol).font(.system(size: 8)).foregroundStyle(tone.color).padding(.top, 4)
                    Text(item).font(.system(size: 12)).foregroundStyle(Theme.creamDim)
                }
            }
        }
    }
}

// MARK: - Concussion

struct ConcussionSection: View {
    @Environment(AppState.self) private var app

    var body: some View {
        VStack(spacing: 12) {
            Card {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.rubyBright)
                        Text("Medical emergency signs").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.rubyBright)
                    }
                    Text("Loss of consciousness, repeated vomiting, worsening headache, slurred speech, vision changes, or weakness after any head impact → emergency care now. This module is for tracking a clinician-managed recovery, not replacing one.")
                        .font(.system(size: 11.5)).foregroundStyle(Theme.creamDim)
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        EyebrowLabel(text: "Daily Symptom Check")
                        Spacer()
                        Chip(text: "0–6 scale", tone: .neutral)
                    }
                    ForEach(app.injuries.concussionSymptoms) { symptom in
                        ConcussionSymptomRow(symptom: symptom)
                    }
                    CoachNote(text: "Sample data. Log symptoms twice daily after any head impact and follow your clinician's return-to-play plan — Forge tracks it, it doesn't decide it.")
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 10) {
                    EyebrowLabel(text: "Return-to-Play · 7 Stages")
                    Text("Advance only after 24 symptom-free hours at the current stage.")
                        .font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                    ForEach(app.injuries.rtpStages) { stage in
                        HStack(alignment: .top, spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(stage.completed ? Theme.green.opacity(0.12) : Theme.card)
                                    .frame(width: 28, height: 28)
                                    .overlay(Circle().stroke(stage.completed ? Theme.green.opacity(0.5) : Theme.hairline, lineWidth: 1))
                                if stage.completed {
                                    Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.green)
                                } else {
                                    Text("\(stage.number)").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.gold)
                                }
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text(stage.name).font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.cream)
                                Text(stage.detail).font(.system(size: 11)).foregroundStyle(Theme.muted)
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
        }
    }
}

struct ConcussionSymptomRow: View {
    @Environment(AppState.self) private var app
    let symptom: ConcussionSymptom

    var body: some View {
        HStack(spacing: 10) {
            Text(symptom.name)
                .font(.system(size: 12)).foregroundStyle(Theme.creamDim)
                .frame(width: 120, alignment: .leading)
            HStack(spacing: 5) {
                ForEach(0...6, id: \.self) { i in
                    Button {
                        app.injuries.setSymptom(symptom, value: i)
                    } label: {
                        Circle()
                            .fill(i <= symptom.value && symptom.value > 0
                                  ? (symptom.value >= 4 ? Theme.ruby : Theme.amber)
                                  : Theme.card)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(i == symptom.value ? Theme.gold : Theme.hairline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
            Text("\(symptom.value)").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.cream)
        }
    }
}

// MARK: - Return to sport

struct ReturnToSportSection: View {
    @Environment(AppState.self) private var app

    var body: some View {
        VStack(spacing: 12) {
            Card(gold: true) {
                VStack(alignment: .leading, spacing: 12) {
                    EyebrowLabel(text: "Active · Left Knee")
                    Text("Return-to-Training Checklist").font(Theme.display(19)).foregroundStyle(Theme.cream)
                    Text("Hockey-specific clearance. Tap to check off as you clear each gate with your PT.")
                        .font(.system(size: 11.5)).foregroundStyle(Theme.muted)

                    ForEach(app.injuries.rtsChecklist) { item in
                        Button {
                            app.injuries.toggleChecklist(item)
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(item.done ? Theme.green : Theme.faint.opacity(0.5))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.label)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(item.done ? Theme.muted : Theme.cream)
                                        .strikethrough(item.done, color: Theme.muted)
                                        .multilineTextAlignment(.leading)
                                    Text(item.detail).font(.system(size: 10.5)).foregroundStyle(Theme.faint)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 3)
                    }

                    let done = app.injuries.rtsChecklist.filter(\.done).count
                    let total = app.injuries.rtsChecklist.count
                    CapsuleBar(value: Double(done), target: Double(total), tone: .green, height: 7)
                    Text("\(done) of \(total) self-check gates done · only your PT or physician can clear your return")
                        .font(.system(size: 11)).foregroundStyle(Theme.gold)
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 8) {
                    EyebrowLabel(text: "Surgery Recovery Module")
                    Text("Post-op tracking — week-by-week milestones, ROM goals, swelling and pain logs, and graded loading templates (ACL, meniscus, labrum, rotator cuff). Activates when you log a surgery with your clinician's timeline.")
                        .font(.system(size: 12)).foregroundStyle(Theme.creamDim)
                    Chip(text: "No active surgical recovery", tone: .green)
                }
            }
        }
    }
}
