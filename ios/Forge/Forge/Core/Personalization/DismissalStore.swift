import Foundation

/// Persists `DismissalMemory` on-device so a brushed-away insight stays quiet across
/// launches — the durable half of "never annoying". Local only; not synced.
struct DismissalStore {
    var defaults: UserDefaults = .standard
    private let key = "forge.insights.dismissed.v1"

    func load() -> DismissalMemory {
        guard let data = defaults.data(forKey: key),
              let mem = try? JSONDecoder().decode(DismissalMemory.self, from: data) else { return DismissalMemory() }
        return mem
    }

    func save(_ mem: DismissalMemory) {
        if let data = try? JSONEncoder().encode(mem) { defaults.set(data, forKey: key) }
    }

    /// Record a dismissal and persist it.
    func recordDismissal(_ id: String, at: Date = .now) {
        var mem = load()
        mem.recordDismissal(id, at: at)
        save(mem)
    }
}
