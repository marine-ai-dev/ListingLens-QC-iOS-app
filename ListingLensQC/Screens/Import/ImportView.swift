import SwiftUI
import PhotosUI
#if canImport(ListingLensQCCore)
import ListingLensQCCore
#endif

struct ImportView: View {
    @EnvironmentObject private var theme: AppTheme
    @StateObject private var viewModel = AuditViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var navigateToProgress = false

    init() {}

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        Spacer(minLength: Spacing.lg)

                        VStack(spacing: Spacing.lg) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 64))
                                .foregroundStyle(theme.selectedAccent.color)
                                .accessibilityHidden(true)
                            Text("ListingLens QC")
                                .font(.largeTitle.bold())
                            Text("Select up to 20 product photos to check quality on this device. Nothing leaves your phone.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, Spacing.lg)

                            PhotosPicker(selection: $selectedItems, maxSelectionCount: AnalysisConfig.maxBatchSize, matching: .images) {
                                Text("Select Photos")
                                    .font(.body.weight(.semibold))
                                    .frame(maxWidth: .infinity, minHeight: Metrics.minTouchTarget)
                            }
                            .background(theme.selectedAccent.color, in: RoundedRectangle(cornerRadius: Radius.md))
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.lg)
                            .accessibilityIdentifier("import.selectPhotosButton")
                            .accessibilityHint("Opens your photo library. Choose one to twenty photos.")

                            if let error = viewModel.errorMessage {
                                Text(error).foregroundStyle(StatusColor.critical).font(.footnote)
                            }
                        }

                        Spacer(minLength: Spacing.lg)

                        NavigationLink(destination: SettingsView()) {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .accessibilityIdentifier("import.settingsLink")
                        .padding(.bottom, Spacing.lg)
                    }
                    .padding()
                    .frame(minHeight: proxy.size.height)
                }
            }
            .navigationDestination(isPresented: $navigateToProgress) {
                AnalysisProgressView(viewModel: viewModel)
            }
            .onChange(of: selectedItems) { _, newItems in
                Task { await loadItems(newItems) }
            }
        }
    }

    private func loadItems(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return } // user cancelled picker
        var loaded: [PhotoInput] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                loaded.append(PhotoInput(data: data))
            }
        }
        guard !loaded.isEmpty else {
            viewModel.errorMessage = String(localized: "Could not load the selected photos.")
            return
        }
        viewModel.inputs = loaded
        viewModel.errorMessage = nil
        viewModel.startAnalysis()
        navigateToProgress = true
    }
}
