import Foundation
import Observation

@Observable
final class MarketplaceService {
    var coaches: [CoachListing] = MockData.coaches
    var programs: [ProgramListing] = MockData.programs
    var products: [StoreProduct] = MockData.products
}
