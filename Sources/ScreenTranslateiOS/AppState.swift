import Foundation

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var pendingSourceText: String?

    private init() {}
}
