import ActivityKit

/// Starts the Live Activity the instant the intent runs (so the Dynamic
/// Island shows "Translating..." as soon as the app flashes open), then
/// updates it once the real on-device translation finishes — at which point
/// the user can immediately swipe back to whatever app they were in and
/// check the result from the Dynamic Island, no need to sit on our screen.
@MainActor
enum LiveActivityManager {
    private static var current: Activity<ScreenTranslateAttributes>?

    static func start() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Log.intent.error("Live Activities not enabled (check Settings > Face ID & Passcode / Screen Time restrictions, or per-app in Settings > ScreenTranslate)")
            return
        }

        let state = ScreenTranslateAttributes.ContentState(status: .translating, text: "")
        do {
            current = try Activity.request(
                attributes: ScreenTranslateAttributes(),
                content: .init(state: state, staleDate: nil)
            )
            Log.intent.debug("live activity started")
        } catch {
            Log.intent.error("failed to start live activity: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func finish(status: ScreenTranslateAttributes.ContentState.Status, text: String) async {
        guard let activity = current else {
            Log.intent.error("no active live activity to finish")
            return
        }
        let state = ScreenTranslateAttributes.ContentState(status: status, text: text)
        await activity.update(.init(state: state, staleDate: nil))
        Log.intent.debug("live activity updated: status=\(status.rawValue, privacy: .public)")
    }
}
