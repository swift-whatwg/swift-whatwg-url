public import Byte
import ASCII
import Byte

extension WHATWG_URL.URL {

    public struct Scheme: Hashable, Sendable {

        public let value: String

        private init(__unchecked: Void, value: String) {
            self.value = value
        }

        public init(_ value: some StringProtocol) throws(Error) {
            guard !value.isEmpty else {
                throw .emptyScheme
            }

            let bytes = [Byte](utf8: String(value))

            guard bytes[0].bitPattern.ascii.isLetter else {
                throw .mustStartWithAlpha(Character(UnicodeScalar(bytes[0].bitPattern)))
            }

            for byte in bytes.dropFirst() {
                let isValid =
                    byte.bitPattern.ascii.isAlphanumeric || byte == ASCII.Code.plus.byte
                    || byte == ASCII.Code.hyphen.byte || byte == ASCII.Code.period.byte

                guard isValid else {
                    throw .invalidCharacter(Character(UnicodeScalar(byte.bitPattern)))
                }
            }

            self.init(__unchecked: (), value: value.lowercased())
        }
    }
}

extension WHATWG_URL.URL.Scheme {

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        try self.init(String(decoding: bytes, as: UTF8.self))
    }
}

extension WHATWG_URL.URL.Scheme {

    private static let specialSchemes: [String: UInt16?] = [
        "ftp": 21,
        "file": nil,
        "http": 80,
        "https": 443,
        "ws": 80,
        "wss": 443,
    ]

    public static func isSpecial(_ scheme: Self) -> Bool {
        specialSchemes.keys.contains(scheme.value)
    }

    public static func defaultPort(for scheme: Self) -> UInt16? {

        specialSchemes[scheme.value].flatMap { $0 }
    }
}

extension WHATWG_URL.URL.Scheme {

    public static let http = Self(__unchecked: (), value: "http")

    public static let https = Self(__unchecked: (), value: "https")

    public static let file = Self(__unchecked: (), value: "file")

    public static let ftp = Self(__unchecked: (), value: "ftp")

    public static let ws = Self(__unchecked: (), value: "ws")

    public static let wss = Self(__unchecked: (), value: "wss")
}

extension WHATWG_URL.URL.Scheme: CustomStringConvertible {

    public var description: String { value }
}
