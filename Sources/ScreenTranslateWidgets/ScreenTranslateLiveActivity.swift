import ActivityKit
import WidgetKit
import SwiftUI

struct ScreenTranslateLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ScreenTranslateAttributes.self) { context in
            LockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    ExpandedView(state: context.state)
                }
            } compactLeading: {
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(.tint)
            } compactTrailing: {
                switch context.state.status {
                case .translating:
                    ProgressView()
                        .scaleEffect(0.6)
                case .done:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                case .failed:
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                }
            } minimal: {
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(.tint)
            }
        }
    }
}

private struct LockScreenView: View {
    let state: ScreenTranslateAttributes.ContentState

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            statusIcon
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(statusLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if state.status != .translating {
                    Text(state.text)
                        .font(.body)
                        .lineLimit(4)
                }
            }
        }
        .padding(16)
        .activityBackgroundTint(Color.black.opacity(0.6))
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch state.status {
        case .translating:
            ProgressView()
        case .done:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
        }
    }

    private var statusLabel: String {
        switch state.status {
        case .translating: "Translating…"
        case .done: "Translation"
        case .failed: "Couldn't translate"
        }
    }
}

private struct ExpandedView: View {
    let state: ScreenTranslateAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(state.status == .translating ? "Translating…" : "Translation")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if state.status == .translating {
                ProgressView()
            } else {
                Text(state.text)
                    .font(.footnote)
                    .lineLimit(6)
            }
        }
        .padding(.horizontal, 8)
    }
}

@main
struct ScreenTranslateWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ScreenTranslateLiveActivity()
    }
}
