import SwiftUI

/// Reusable loading / empty / error states — consistent across every feature.

struct LoadingStateView: View {
    var label = "Loading"

    var body: some View {
        VStack(spacing: 10) {
            ProgressView().tint(Theme.gold)
            Text(label.uppercased())
                .font(Theme.eyebrow(9))
                .kerning(2)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundStyle(Theme.gold.opacity(0.5))
            Text(title)
                .font(Theme.display(20))
                .foregroundStyle(Theme.cream)
            Text(message)
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            if let actionLabel, let action {
                Button(actionLabel, action: action)
                    .buttonStyle(GoldButtonStyle(compact: true))
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

struct ErrorBanner: View {
    let message: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundStyle(Theme.rubyBright)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Theme.creamDim)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            if let onDismiss {
                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 11).fill(Theme.ruby.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.ruby.opacity(0.35), lineWidth: 1))
    }
}
