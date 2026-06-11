import Foundation
import Observation

@Observable
final class RecoveryService {
    var today: RecoveryData = MockData.today
    var wearables: [WearableDevice] = MockData.wearables

    let trends: [TrendSeries] = [
        TrendSeries(name: "Recovery", unit: "/100", values: MockData.recoveryTrend),
        TrendSeries(name: "HRV", unit: "ms", values: MockData.hrvTrend),
        TrendSeries(name: "Sleep", unit: "h", values: MockData.sleepTrend),
        TrendSeries(name: "Strain", unit: "/21", values: MockData.strainTrend),
    ]

    var forgeScoreTrend: [Double] { MockData.forgeScoreTrend }

    var connectedCount: Int { wearables.filter(\.connected).count }

    func toggleConnection(_ device: WearableDevice) {
        guard let idx = wearables.firstIndex(where: { $0.id == device.id }) else { return }
        wearables[idx].connected.toggle()
        wearables[idx].lastSync = wearables[idx].connected ? "just now" : nil
    }
}
