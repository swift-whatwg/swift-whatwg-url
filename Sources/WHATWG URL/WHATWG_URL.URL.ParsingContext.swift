extension WHATWG_URL.URL {

    public struct ParsingContext: Sendable {

        public let base: WHATWG_URL.URL?

        public init(base: WHATWG_URL.URL? = nil) {
            self.base = base
        }
    }
}

extension WHATWG_URL.URL.ParsingContext {

    public static let none = WHATWG_URL.URL.ParsingContext(base: nil)
}
