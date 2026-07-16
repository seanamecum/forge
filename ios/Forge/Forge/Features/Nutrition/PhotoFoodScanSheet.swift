import SwiftUI
import PhotosUI
import Vision

/// Real photo food logging: on-device Vision classification (no network, no
/// key) matched against the food database. Honest about its limits — when it
/// can't identify the plate it says so and points to Search/Scan.
struct PhotoFoodScanSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    let meal: MealType
    @State private var pickerItem: PhotosPickerItem?
    @State private var phase: Phase = .pick

    enum Phase {
        case pick
        case analyzing
        case matched([Food])
        case unmatched([String])   // what Vision saw, even if no DB match
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 16) {
                    switch phase {
                    case .pick:
                        Spacer()
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 40)).foregroundStyle(Theme.gold.opacity(0.8))
                        Text("Snap or pick a photo of your plate")
                            .font(Theme.display(18)).foregroundStyle(Theme.cream)
                        Text("Recognition runs on this phone — nothing is uploaded.")
                            .font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Text("Choose photo")
                        }
                        .buttonStyle(GoldButtonStyle(compact: true))
                        Spacer()

                    case .analyzing:
                        Spacer()
                        ProgressView().tint(Theme.gold)
                        Text("Identifying food…")
                            .font(.system(size: 12)).foregroundStyle(Theme.muted)
                        Spacer()

                    case .matched(let foods):
                        ScrollView {
                            VStack(spacing: 10) {
                                Text("Tap what's on the plate")
                                    .font(.system(size: 12)).foregroundStyle(Theme.muted)
                                ForEach(foods) { food in
                                    matchRow(food)
                                }
                                retryButton
                            }
                            .padding(16)
                        }

                    case .unmatched(let labels):
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 32)).foregroundStyle(Theme.amber)
                            Text(labels.isEmpty
                                 ? "Couldn't identify food in that photo."
                                 : "Saw \(labels.prefix(3).joined(separator: ", ")) — no match in the food database yet.")
                                .font(.system(size: 13)).foregroundStyle(Theme.cream)
                                .multilineTextAlignment(.center)
                            Text("Use Search or Scan for anything packaged — those always work.")
                                .font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                                .multilineTextAlignment(.center)
                            retryButton
                        }
                        .padding(.horizontal, 24)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Photo Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Theme.gold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            phase = .analyzing
            Task { await analyze(item) }
        }
    }

    private var retryButton: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            Text("Try another photo")
        }
        .buttonStyle(GhostButtonStyle(compact: true))
    }

    private func matchRow(_ food: Food) -> some View {
        Button {
            Haptics.success()
            app.nutrition.add(food: food, to: meal)
        } label: {
            Card {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(food.name).font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.cream)
                        Text(food.serving).font(.system(size: 11)).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Text("\(food.calories) kcal · \(Int(food.protein))P")
                        .font(.system(size: 12)).foregroundStyle(Theme.gold)
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18)).foregroundStyle(Theme.gold)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Vision

    private func analyze(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)?.cgImage else {
            await MainActor.run { phase = .unmatched([]) }
            return
        }
        let labels = FoodVision.classify(image)
        let matches = FoodVision.match(labels: labels, in: app.nutrition.foods)
        await MainActor.run {
            phase = matches.isEmpty ? .unmatched(labels) : .matched(matches)
        }
    }
}

/// Pure matching logic split out so it's unit-testable without Vision.
enum FoodVision {
    /// Top food-plausible labels from the on-device classifier.
    static func classify(_ image: CGImage, minConfidence: Float = 0.15) -> [String] {
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: image)
        guard (try? handler.perform([request])) != nil,
              let observations = request.results else { return [] }
        return observations
            .filter { $0.confidence >= minConfidence }
            .prefix(8)
            .map { $0.identifier.replacingOccurrences(of: "_", with: " ") }
    }

    /// Match classifier labels against the food database by word overlap.
    static func match(labels: [String], in foods: [Food]) -> [Food] {
        var seen = Set<String>()
        var result: [Food] = []
        for label in labels {
            let words = Set(label.lowercased().split(separator: " ").map(String.init))
            for food in foods {
                let nameWords = Set(food.name.lowercased()
                    .split(whereSeparator: { !$0.isLetter }).map(String.init))
                guard !words.isDisjoint(with: nameWords), !seen.contains(food.id) else { continue }
                seen.insert(food.id)
                result.append(food)
            }
        }
        return Array(result.prefix(6))
    }
}
