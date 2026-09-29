extension WHATWG_URL.URL {

    public struct Href: Hashable, Sendable {

        public let value: String

        private init(__unchecked: Void, value: String) {
            self.value = value
        }

        public init(_ url: WHATWG_URL.URL) {

            self.init(__unchecked: (), value: url.description)
        }
    }
}

extension WHATWG_URL.URL.Href {

    public init(_ string: some StringProtocol) throws(WHATWG_URL.URL.Error) {
        self.init(try WHATWG_URL.URL(string))
    }
}

extension WHATWG_URL.URL.Href: CustomStringConvertible {

    public var description: String { value }
}
