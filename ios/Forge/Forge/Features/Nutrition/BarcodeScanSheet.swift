import SwiftUI
import VisionKit

/// Real barcode scanning (VisionKit) → OpenFoodFacts lookup → one-tap log.
/// Degrades honestly: no camera / simulator → manual barcode entry, same lookup.
struct BarcodeScanSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    let meal: MealType
    @State private var phase: Phase = .scanning
    @State private var manualCode = ""

    enum Phase: Equatable {
        case scanning
        case looking(String)
        case found(Food)
        case failed(String)
    }

    private var scannerSupported: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 16) {
                    switch phase {
                    case .scanning:
                        if scannerSupported {
                            BarcodeCameraView { code in
                                guard case .scanning = phase else { return }
                                Haptics.tap()
                                lookup(code)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .frame(maxHeight: 380)
                            .padding(.horizontal, 16)
                            Text("Point at any food barcode")
                                .font(.system(size: 12)).foregroundStyle(Theme.muted)
                        } else {
                            manualEntry(reason: "Camera scanning isn't available on this device — type the barcode instead.")
                        }
                        Spacer()

                    case .looking(let code):
                        Spacer()
                        ProgressView().tint(Theme.gold)
                        Text("Looking up \(code)…")
                            .font(.system(size: 12)).foregroundStyle(Theme.muted)
                        Spacer()

                    case .found(let food):
                        foundCard(food)
                        Spacer()

                    case .failed(let message):
                        Spacer()
                        ErrorBanner(message: message).padding(.horizontal, 16)
                        Button("Scan again") { phase = .scanning }
                            .buttonStyle(GhostButtonStyle(compact: true))
                        manualEntry(reason: nil)
                        Spacer()
                    }
                }
                .padding(.top, 12)
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Theme.gold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func lookup(_ code: String) {
        phase = .looking(code)
        Task { @MainActor in
            do {
                let food = try await OpenFoodFacts.lookup(barcode: code)
                Haptics.success()
                phase = .found(food)
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    @ViewBuilder
    private func manualEntry(reason: String?) -> some View {
        VStack(spacing: 10) {
            if let reason {
                Text(reason)
                    .font(.system(size: 12)).foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            HStack(spacing: 8) {
                TextField("Barcode number", text: $manualCode)
                    .keyboardType(.numberPad)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(Theme.cream)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
                Button("Look up") {
                    guard manualCode.count >= 8 else { return }
                    lookup(manualCode)
                }
                .buttonStyle(GoldButtonStyle(compact: true))
            }
            .padding(.horizontal, 16)
        }
    }

    private func foundCard(_ food: Food) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text(food.name)
                    .font(Theme.display(20)).foregroundStyle(Theme.cream)
                if let brand = food.brand {
                    Text(brand).font(.system(size: 12)).foregroundStyle(Theme.muted)
                }
                Text("Per \(food.serving) · OpenFoodFacts")
                    .font(.system(size: 11)).foregroundStyle(Theme.faint)
                HStack(spacing: 14) {
                    StatTile(label: "Calories", value: "\(food.calories)", tone: .gold)
                    StatTile(label: "Protein", value: String(format: "%.0f", food.protein), unit: "g")
                    StatTile(label: "Carbs", value: String(format: "%.0f", food.carbs), unit: "g")
                    StatTile(label: "Fat", value: String(format: "%.0f", food.fat), unit: "g")
                }
                Button("Add to \(meal.rawValue)") {
                    Haptics.success()
                    app.nutrition.add(food: food, to: meal)
                    dismiss()
                }
                .buttonStyle(GoldButtonStyle())
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - VisionKit wrapper

private struct BarcodeCameraView: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .ean8, .upce, .code128])],
            qualityLevel: .fast,
            isHighlightingEnabled: true)
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ vc: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void
        init(onScan: @escaping (String) -> Void) { self.onScan = onScan }

        func dataScanner(_ scanner: DataScannerViewController,
                         didAdd added: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in added {
                if case .barcode(let barcode) = item, let value = barcode.payloadStringValue {
                    scanner.stopScanning()
                    onScan(value)
                    return
                }
            }
        }
    }
}
