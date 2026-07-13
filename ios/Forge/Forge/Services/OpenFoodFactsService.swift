import Foundation

/// Real barcode → nutrition lookup via OpenFoodFacts — the free, open food
/// database (no API key). Pure decoding is separated from transport so it's
/// unit-tested; the app degrades gracefully offline (manual entry still works).
enum OpenFoodFacts {

    enum LookupError: LocalizedError, Equatable {
        case notFound
        case badResponse

        var errorDescription: String? {
            switch self {
            case .notFound: return "Product not in the OpenFoodFacts database. Log it manually — takes ten seconds."
            case .badResponse: return "Couldn't reach the food database. Check your connection or log manually."
            }
        }
    }

    // MARK: - Wire format (only the fields Forge uses)

    struct Response: Decodable {
        let status: Int
        let product: Product?
    }

    struct Product: Decodable {
        let productName: String?
        let brands: String?
        let nutriments: Nutriments?

        enum CodingKeys: String, CodingKey {
            case productName = "product_name"
            case brands, nutriments
        }
    }

    struct Nutriments: Decodable {
        let kcal100: Double?
        let protein100: Double?
        let carbs100: Double?
        let fat100: Double?
        let fiber100: Double?
        let sugar100: Double?

        enum CodingKeys: String, CodingKey {
            case kcal100 = "energy-kcal_100g"
            case protein100 = "proteins_100g"
            case carbs100 = "carbohydrates_100g"
            case fat100 = "fat_100g"
            case fiber100 = "fiber_100g"
            case sugar100 = "sugars_100g"
        }
    }

    // MARK: - Decode (pure, tested)

    /// Build a Forge `Food` (per 100 g) from an OpenFoodFacts payload.
    static func food(fromJSON data: Data, barcode: String) throws -> Food {
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard decoded.status == 1, let product = decoded.product,
              let name = product.productName, !name.isEmpty,
              let n = product.nutriments, let kcal = n.kcal100
        else { throw LookupError.notFound }

        return Food(
            id: "off-\(barcode)",
            name: name,
            brand: product.brands?.split(separator: ",").first.map(String.init),
            serving: "100 g",
            calories: Int(kcal.rounded()),
            protein: n.protein100 ?? 0,
            carbs: n.carbs100 ?? 0,
            fat: n.fat100 ?? 0,
            fiber: n.fiber100 ?? 0,
            sugar: n.sugar100 ?? 0)
    }

    // MARK: - Transport

    static func lookup(barcode: String) async throws -> Food {
        let fields = "product_name,brands,nutriments"
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=\(fields)")
        else { throw LookupError.badResponse }
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("Forge iOS prototype - github.com/seanamecum/forge", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw LookupError.badResponse
            }
            return try food(fromJSON: data, barcode: barcode)
        } catch let e as LookupError {
            throw e
        } catch {
            throw LookupError.badResponse
        }
    }
}
