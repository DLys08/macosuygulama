import Foundation

/// Lenient decoding helpers. Every persisted model decodes missing or malformed
/// keys to a sensible default, so a schema change or a single bad value never
/// discards the user's whole layout.
extension KeyedDecodingContainer {
    func value<T: Decodable>(_ key: Key, default fallback: T) -> T {
        if let decoded = try? decodeIfPresent(T.self, forKey: key) {
            return decoded
        }
        return fallback
    }

    func optionalValue<T: Decodable>(_ key: Key) -> T? {
        if let decoded = try? decodeIfPresent(T.self, forKey: key) {
            return decoded
        }
        return nil
    }

    /// Decodes an array element by element, dropping only the elements that fail.
    func lossyArray<T: Decodable>(_ key: Key) -> [T] {
        guard var container = try? nestedUnkeyedContainer(forKey: key) else { return [] }
        var result: [T] = []
        while !container.isAtEnd {
            if let element = try? container.decode(T.self) {
                result.append(element)
            } else {
                // Skip the undecodable element.
                _ = try? container.decode(AnyDecodableSkip.self)
            }
        }
        return result
    }
}

/// Consumes any JSON value so a lossy array can move past a bad element.
struct AnyDecodableSkip: Decodable {
    init(from decoder: Decoder) throws {}
}
