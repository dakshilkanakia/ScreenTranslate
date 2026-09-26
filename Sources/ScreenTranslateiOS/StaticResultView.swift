import SwiftUI

/// Plain, already-final result — no async work left to do once this is
/// shown, so there's nothing for Siri's snippet teardown to race against.
struct StaticResultView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
    }
}
