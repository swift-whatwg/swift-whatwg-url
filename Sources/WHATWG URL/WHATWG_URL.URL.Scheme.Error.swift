extension WHATWG_URL.URL.Scheme {

    public enum Error: Swift::Error, Hashable, Sendable {

        case emptyScheme

        case mustStartWithAlpha(Character)

        case invalidCharacter(Character)
    }
}
