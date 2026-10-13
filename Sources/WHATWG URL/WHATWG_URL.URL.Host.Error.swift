extension WHATWG_URL.URL.Host {

    public enum Error: Swift::Error, Hashable, Sendable {

        case invalidDomain(String)

        case invalidIPv4Address(String)

        case invalidIPv6Address(String)

        case invalidOpaqueHost(String)

        case emptyHostNotAllowed

        case forbiddenHostCodePoint(Character)

        case ipv6BracketMismatch
    }
}
