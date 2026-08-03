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
    @State private var adjusting: CanonicalFood?

    enum Phase: Equatable {
        case scanning
        case looking(String)
        case found(CanonicalFood)
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
            .sheet(item: $adjusting) { food in
                LogFoodSheet(food: food, meal: meal, onLogged: { dismiss() })
            }
        }
        .preferredColorScheme(.dark)
    }

    private func lookup(_ code: String) {
        phase = .looking(code)
        Task { @MainActor in
            if let food = await app.lookupBarcode(code) {
                Haptics.success()
                phase = .found(food)
            } else {
                phase = .failed(OpenFoodFacts.LookupError.notFound.errorDescription ?? "Not found.")
            }
        }
    }

    /// A sensible default quantity — the user's remembered serving for this food, else
    /// one natural portion (or 100 g for a bare per-100 g product).
    private func defaultQuantity(for food: CanonicalFood) -> FoodQuantity {
        if let last = FoodQuantityMemory().last(foodID: food.id), food.unit(id: last.unitID) != nil {
            return FoodQuantity(amount: last.amount, unitID: last.unitID)
        }
        let unit = food.defaultUnit
        return unit.kind == .mass ? FoodQuantity(amount: 100, unitID: "g")
                                  : FoodQuantity(amount: 1, unitID: unit.id)
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

    private func foundCard(_ food: CanonicalFood) -> some View {
        let q = defaultQuantity(for: food)
        let n = food.nutrients(for: q).nutrients
        let unitLabel = food.unit(id: q.unitID)?.label ?? "g"
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                Text(food.name).font(Theme.display(20)).foregroundStyle(Theme.cream)
                HStack(spacing: 6) {
                    if let brand = food.brand { Text(brand).font(.system(size: 12)).foregroundStyle(Theme.muted) }
                    SourceBadge(food: food)
                }
                Text("Per \(String(format: "%g", q.amount)) \(unitLabel)")
                    .font(.system(size: 11)).foregroundStyle(Theme.faint)
                HStack(spacing: 14) {
                    StatTile(label: "Calories", value: "\(Int((n?[.calories] ?? 0).rounded()))", tone: .gold)
                    StatTile(label: "Protein", value: String(format: "%.0f", n?[.protein] ?? 0), unit: "g")
                    StatTile(label: "Carbs", value: String(format: "%.0f", n?[.carbs] ?? 0), unit: "g")
                    StatTile(label: "Fat", value: String(format: "%.0f", n?[.fat] ?? 0), unit: "g")
                }
                HStack(spacing: 8) {
                    Button("Add to \(meal.rawValue)") {
                        Haptics.success()
                        app.logFood(food, quantity: q, meal: meal)
                        dismiss()
                    }
                    .buttonStyle(GoldButtonStyle())
                    Button("Adjust") { adjusting = food }
                        .buttonStyle(GhostButtonStyle(compact: true))
                }
                Button("Scan another") { phase = .scanning }
                    .font(.system(size: 12)).foregroundStyle(Theme.muted)
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
