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

    struct SearchResponse: Decodable { let products: [Product] }

    struct Product: Decodable {
        let code: String?
        let productName: String?
        let brands: String?
        let nutriments: Nutriments?
        let servingQuantity: Double?      // grams per serving, when known

        enum CodingKeys: String, CodingKey {
            case code, brands, nutriments
            case productName = "product_name"
            case servingQuantity = "serving_quantity"
        }
    }

    struct Nutriments: Decodable {
        let kcal100: Double?
        let protein100: Double?
        let carbs100: Double?
        let fat100: Double?
        let fiber100: Double?
        let sugar100: Double?
        let satFat100: Double?
        let sodium100: Double?             // grams per 100 g

        enum CodingKeys: String, CodingKey {
            case kcal100 = "energy-kcal_100g"
            case protein100 = "proteins_100g"
            case carbs100 = "carbohydrates_100g"
            case fat100 = "fat_100g"
            case fiber100 = "fiber_100g"
            case sugar100 = "sugars_100g"
            case satFat100 = "saturated-fat_100g"
            case sodium100 = "sodium_100g"
        }
    }

    // MARK: - Canonical mapping (pure, tested)

    /// Build a grams-canonical `CanonicalFood` (per 100 g, source-tagged, confidence-
    /// scored) from an OpenFoodFacts product. `serving_quantity` becomes a portion.
    /// nil when there isn't enough to be a real, loggable food.
    static func canonicalFood(from p: Product) -> CanonicalFood? {
        guard let name = p.productName, !name.isEmpty, let n = p.nutriments, let kcal = n.kcal100 else { return nil }
        var vals: [Nutrient: Double] = [.calories: kcal]
        if let x = n.protein100 { vals[.protein] = x }
        if let x = n.carbs100 { vals[.carbs] = x }
        if let x = n.fat100 { vals[.fat] = x }
        if let x = n.fiber100 { vals[.fiber] = x }
        if let x = n.sugar100 { vals[.sugar] = x }
        if let x = n.satFat100 { vals[.saturatedFat] = x }
        if let x = n.sodium100 { vals[.sodium] = x * 1000 }        // g → mg
        var portions: [ServingUnit] = []
        if let g = p.servingQuantity, g > 0 {
            portions.append(.portion(id: "serving", label: "serving", grams: g, source: .off))
        }
        return CanonicalFood(id: "off-\(p.code ?? UUID().uuidString)", name: name,
                             brand: p.brands?.split(separator: ",").first.map(String.init),
                             per100g: NutrientVector(vals), portions: portions,
                             source: .openFoodFacts, upc: p.code)
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

    /// Barcode → grams-canonical food (global coverage). nil when not found.
    static func lookupCanonical(barcode: String, session: URLSession = .shared) async -> CanonicalFood? {
        let fields = "code,product_name,brands,nutriments,serving_quantity"
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=\(fields)")
        else { return nil }
        var req = URLRequest(url: url); req.timeoutInterval = 12
        req.setValue("Forge iOS - github.com/seanamecum/forge", forHTTPHeaderField: "User-Agent")
        guard let (data, resp) = try? await session.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode(Response.self, from: data),
              decoded.status == 1, let product = decoded.product else { return nil }
        return canonicalFood(from: product)
    }

    /// Full-text search → canonical foods (global, all languages).
    static func searchCanonical(_ query: String, limit: Int, session: URLSession = .shared) async -> [CanonicalFood] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty,
              var comps = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl") else { return [] }
        comps.queryItems = [
            .init(name: "search_terms", value: query), .init(name: "search_simple", value: "1"),
            .init(name: "action", value: "process"), .init(name: "json", value: "1"),
            .init(name: "page_size", value: String(limit)),
            .init(name: "fields", value: "code,product_name,brands,nutriments,serving_quantity"),
        ]
        guard let url = comps.url else { return [] }
        var req = URLRequest(url: url); req.timeoutInterval = 12
        req.setValue("Forge iOS - github.com/seanamecum/forge", forHTTPHeaderField: "User-Agent")
        guard let (data, resp) = try? await session.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode(SearchResponse.self, from: data) else { return [] }
        return decoded.products.compactMap(canonicalFood(from:))
    }
}

/// Open Food Facts as a `FoodSearchProvider` — global barcoded/packaged foods.
struct OpenFoodFactsProvider: FoodSearchProvider {
    let id = "openfoodfacts"
    var session: URLSession = .shared
    func search(_ query: String, limit: Int) async -> [CanonicalFood] {
        await OpenFoodFacts.searchCanonical(query, limit: limit, session: session)
    }
    func lookup(barcode: String) async -> CanonicalFood? {
        await OpenFoodFacts.lookupCanonical(barcode: barcode, session: session)
    }
}
