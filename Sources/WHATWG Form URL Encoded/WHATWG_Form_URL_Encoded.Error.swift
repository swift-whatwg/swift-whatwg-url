extension WHATWG_Form_URL_Encoded.PercentEncoding {

    public enum Error: Swift::Error, Hashable, Sendable {

        case invalidPercentEncoding(position: Int, found: String)

        case invalidHexDigit(Character)

        case invalidUTF8Sequence

        case unexpectedEndOfInput
    }
}
