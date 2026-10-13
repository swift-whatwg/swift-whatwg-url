extension WHATWG_URL.URL.Path {

    public enum Error: Swift::Error, Hashable, Sendable {

        case invalidSegment(String)

        case invalidPercentEncoding(String)
    }
}
