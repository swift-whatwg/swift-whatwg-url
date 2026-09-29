import WHATWG_Form_URL_Encoded

extension WHATWG_URL.URL.Search {

    public struct Params {
        private var pairs: [(String, String)]

        public init() {
            self.pairs = []
        }
    }
}

extension WHATWG_URL.URL.Search.Params {

    public init(_ query: some StringProtocol) {
        let cleaned = query.hasPrefix("?") ? String(query.dropFirst()) : String(query)
        self.pairs = WHATWG_Form_URL_Encoded.parse(cleaned)
    }

    public init(_ pairs: [(String, String)]) {
        self.pairs = pairs
    }
}

extension WHATWG_URL.URL.Search.Params {

    public mutating func append(_ name: String, _ value: String) {
        pairs.append((name, value))
    }

    public mutating func delete(_ name: some StringProtocol) {
        pairs.removeAll { $0.0 == name }
    }

    public func get(_ name: some StringProtocol) -> String? {
        return pairs.first { $0.0 == name }?.1
    }

    public func getAll(_ name: some StringProtocol) -> [String] {
        return pairs.filter { $0.0 == name }.map { $0.1 }
    }

    public func has(_ name: some StringProtocol) -> Bool {
        return pairs.contains { $0.0 == name }
    }

    public mutating func set(_ name: String, _ value: String) {

        pairs.removeAll { $0.0 == name }

        pairs.append((name, value))
    }

    public mutating func sort() {
        pairs.sort { $0.0 < $1.0 }
    }

    public var entries: [(String, String)] {
        return pairs
    }

    public var count: Int {
        return pairs.count
    }

    public var isEmpty: Bool {
        return pairs.isEmpty
    }
}

extension WHATWG_URL.URL.Search.Params: Swift.Sequence {
    public func makeIterator() -> IndexingIterator<[(String, String)]> {
        return pairs.makeIterator()
    }
}

extension WHATWG_URL.URL.Search.Params: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        self.pairs = elements
    }
}

extension WHATWG_URL.URL.Search.Params: CustomStringConvertible {
    public var description: String {
        return WHATWG_Form_URL_Encoded.serialize(pairs)
    }
}
