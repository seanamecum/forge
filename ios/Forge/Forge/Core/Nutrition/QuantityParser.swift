import Foundation

/// Parses the free-form quantity a user types into a number: decimals ("0.5", ".5"),
/// plain fractions ("1/2"), and mixed numbers ("1 1/2"). Returns nil for anything
/// unparseable so the caller can reject it rather than guess.
enum QuantityParser {
    static func parse(_ raw: String) -> Double? {
        let s = raw.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty else { return nil }

        // Mixed number: "1 1/2"
        let parts = s.split(separator: " ").map(String.init)
        if parts.count == 2, let whole = Double(parts[0]), let frac = fraction(parts[1]) {
            return whole + frac
        }
        // Plain fraction: "3/4"
        if let f = fraction(s) { return f }
        // Decimal / integer.
        return Double(s)
    }

    private static func fraction(_ s: String) -> Double? {
        let c = s.split(separator: "/")
        guard c.count == 2, let n = Double(c[0]), let d = Double(c[1]), d != 0 else { return nil }
        return n / d
    }
}
