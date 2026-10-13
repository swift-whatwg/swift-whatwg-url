extension WHATWG_URL.URL {

    public enum Error: Swift::Error, Hashable, Sendable {

        case emptyInput

        case invalidScheme(String)

        case invalidHost(Host.Error)

        case invalidPort(String)

        case invalidPath(String)

        case invalidStructure(String)

        case invalidPercentEncoding(position: Int, found: String)

        case unexpectedEndOfInput

        case cannotHaveCredentials

        case missingSchemeSeparator
    }
}
