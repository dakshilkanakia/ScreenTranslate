import ActivityKit

/// Shared between the app and the widget extension — both need this type to
/// agree exactly, since ActivityKit serializes ContentState across processes.
struct ScreenTranslateAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var status: Status
        var text: String

        enum Status: String, Codable, Hashable {
            case translating
            case done
            case failed
        }
    }
}
