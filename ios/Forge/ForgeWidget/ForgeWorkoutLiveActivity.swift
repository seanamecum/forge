import WidgetKit
import SwiftUI
import ActivityKit

/// The live workout on the lock screen and Dynamic Island: elapsed time,
/// sets, volume, and a native counting-down rest timer.
struct ForgeWorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenWorkoutView(context: context)
                .activityBackgroundTint(WidgetTheme.bg.opacity(0.92))
                .activitySystemActionForegroundColor(WidgetTheme.gold)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.state.setsLabel)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(WidgetTheme.cream)
                    } icon: {
                        Image(systemName: "dumbbell.fill")
                            .foregroundStyle(WidgetTheme.gold)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let rest = context.state.restEndsAt, rest > .now {
                        Text(timerInterval: Date.now...rest, countsDown: true)
                            .monospacedDigit()
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(WidgetTheme.goldBright)
                            .frame(width: 52)
                    } else {
                        Text(context.state.volumeLabel)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(WidgetTheme.creamDim)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        Text(context.attributes.workoutName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(WidgetTheme.creamDim)
                            .lineLimit(1)
                        ProgressView(value: context.state.progress)
                            .tint(WidgetTheme.gold)
                    }
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(WidgetTheme.gold)
            } compactTrailing: {
                if let rest = context.state.restEndsAt, rest > .now {
                    Text(timerInterval: Date.now...rest, countsDown: true)
                        .monospacedDigit()
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WidgetTheme.goldBright)
                        .frame(width: 40)
                } else {
                    Text(context.state.setsLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WidgetTheme.cream)
                }
            } minimal: {
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(WidgetTheme.gold)
            }
        }
    }
}

private struct LockScreenWorkoutView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(WidgetTheme.gold)
                    Text(context.attributes.workoutName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(WidgetTheme.cream)
                        .lineLimit(1)
                }
                Spacer()
                Text(timerInterval: context.attributes.startedAt...Date.now.addingTimeInterval(60 * 60 * 4),
                     countsDown: false)
                    .monospacedDigit()
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetTheme.goldBright)
                    .frame(maxWidth: 64)
            }

            HStack(spacing: 16) {
                stat(context.state.setsLabel, "SETS", pr: context.state.isPR)
                stat(context.state.volumeLabel, "VOLUME")
                Spacer()
                if let rest = context.state.restEndsAt, rest > .now {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(timerInterval: Date.now...rest, countsDown: true)
                            .monospacedDigit()
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(WidgetTheme.goldBright)
                            .frame(width: 64)
                        Text("REST")
                            .font(.system(size: 7, weight: .semibold))
                            .kerning(1.2)
                            .foregroundStyle(WidgetTheme.muted)
                    }
                }
            }

            ProgressView(value: context.state.progress)
                .tint(WidgetTheme.gold)
        }
        .padding(14)
    }

    private func stat(_ value: String, _ label: String, pr: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetTheme.cream)
                if pr {
                    Text("PR")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(WidgetTheme.bg)
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(Capsule().fill(WidgetTheme.gold))
                }
            }
            Text(label)
                .font(.system(size: 7, weight: .semibold))
                .kerning(1.2)
                .foregroundStyle(WidgetTheme.muted)
        }
    }
}
