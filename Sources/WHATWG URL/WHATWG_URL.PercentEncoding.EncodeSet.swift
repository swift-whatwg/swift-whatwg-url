import ASCII

extension WHATWG_URL.PercentEncoding {

    enum EncodeSet {

        case c0Control

        case fragment

        case query

        case specialQuery

        case path

        case userinfo

        case component
    }
}

extension WHATWG_URL.PercentEncoding.EncodeSet {
    func shouldEncode(_ char: Character) -> Bool {
        let value = UInt32(char.utf8.first!)

        let isC0Control = value <= UInt32(ASCII.Code.us.underlying)

        let isNonASCII = value > UInt32(ASCII.Code.tilde.underlying)

        let alwaysEncode =
            char == " " || char == "\"" || char == "<" || char == ">" || char == "`"

        switch self {
        case .c0Control:
            return isC0Control || isNonASCII

        case .fragment:
            return isC0Control || isNonASCII || alwaysEncode || char == "#"

        case .query, .specialQuery:
            return isC0Control || isNonASCII || alwaysEncode || char == "#"

        case .path:
            return isC0Control || isNonASCII || alwaysEncode || char == "?" || char == "{"
                || char == "}"

        case .userinfo:
            return isC0Control || isNonASCII || alwaysEncode || char == "/" || char == ":"
                || char == ";" || char == "=" || char == "@" || char == "[" || char == "\\"
                || char == "]" || char == "^" || char == "|"

        case .component:
            return isC0Control || isNonASCII || alwaysEncode || char == "/" || char == ":"
                || char == ";" || char == "=" || char == "@" || char == "[" || char == "\\"
                || char == "]" || char == "^" || char == "|" || char == "?" || char == "#"
        }
    }
}
