import SwiftUI
#if canImport(ListingLensQCCore)
import ListingLensQCCore
#endif

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("ListingLens QC").font(.title.bold())
                Text("A native, on-device product photo quality checker for sellers. ListingLens QC analyzes resolution, sharpness, exposure, framing and similarity entirely on your device — no photo or metadata ever leaves your phone.")
                Text("No accounts. No ads. No analytics. No generative AI. No networking.")
                    .font(.footnote).foregroundStyle(.secondary)
                Text("Version 1.0.0")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("About")
    }
}
