import SwiftUI
#if canImport(ListingLensQCCore)
import ListingLensQCCore
#endif

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Privacy").font(.title.bold())
                Text("ListingLens QC performs all photo analysis on your device using Apple's Vision, Core Image and Accelerate frameworks. Your photos, and any measurements derived from them, are never uploaded, transmitted, or shared. The app contains no networking code, no analytics SDKs, and no third-party trackers.")
                Text("See the full Privacy Policy in docs/PRIVACY.md.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Privacy")
    }
}
