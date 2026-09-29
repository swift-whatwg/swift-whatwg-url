public import Byte
import ASCII
import Byte

extension WHATWG_URL.URL: CustomStringConvertible {

    public var description: String {

        var output = scheme.value + ":"

        if let host {
            output += "//"

            if !username.isEmpty || !password.isEmpty {
                output += username
                if !password.isEmpty {
                    output += ":" + password
                }
                output += "@"
            }

            output += host.description

            if let port, Scheme.defaultPort(for: scheme) != port {
                output += ":" + String(port)
            }
        }

        output += path.description

        if let query {
            output += "?" + query
        }

        if let fragment {
            output += "#" + fragment
        }

        return output
    }
}

extension WHATWG_URL.URL {

    public init<Bytes: Swift.Collection>(
        ascii bytes: Bytes,
        in context: ParsingContext
    ) throws(Error) where Bytes.Element == Byte {
        var url = Builder()
        var state = State.schemeStart
        var buffer = ""
        var atSignSeen = false

        let array = [Byte](bytes)

        var startIndex = 0
        var endIndex = array.count
        while startIndex < endIndex
            && (array[startIndex] == ASCII.Code.sp.byte
                || array[startIndex] == ASCII.Code.tab.byte)
        {
            startIndex += 1
        }
        while endIndex > startIndex
            && (array[endIndex - 1] == ASCII.Code.sp.byte
                || array[endIndex - 1] == ASCII.Code.tab.byte)
        {
            endIndex -= 1
        }

        let trimmed = Array(array[startIndex..<endIndex])

        guard !trimmed.isEmpty else {

            if let base = context.base {
                self = base
                return
            }
            throw .emptyInput
        }

        var pointer = 0

        parsing: while pointer <= trimmed.count {
            let c: Byte? = pointer < trimmed.count ? trimmed[pointer] : nil

            switch state {
            case .schemeStart:
                if let ch = c, ch.bitPattern.ascii.isLetter {
                    buffer.append(Character(UnicodeScalar(ch.bitPattern)).lowercased())
                    state = .scheme
                } else if context.base != nil {
                    state = .noScheme
                    pointer -= 1
                } else {
                    throw .invalidScheme(String(decoding: trimmed, as: UTF8.self))
                }

            case .scheme:
                if let ch = c,
                    ch.bitPattern.ascii.isAlphanumeric || ch == ASCII.Code.plus.byte
                        || ch == ASCII.Code.hyphen.byte || ch == ASCII.Code.period.byte
                {
                    buffer.append(Character(UnicodeScalar(ch.bitPattern)).lowercased())
                } else if c == ASCII.Code.colon.byte {
                    do throws(Scheme.Error) {
                        url.scheme = try Scheme(buffer)
                    } catch {
                        throw .invalidScheme(buffer)
                    }
                    buffer = ""

                    if Scheme.isSpecial(url.scheme!) {
                        state = .specialAuthoritySlashes
                    } else if trimmed.indices.contains(pointer + 1)
                        && trimmed[pointer + 1] == ASCII.Code.slash.byte
                    {
                        state = .pathOrAuthority
                        pointer += 1
                    } else {
                        state = .opaquePath
                    }
                } else if context.base != nil {

                    buffer = ""
                    pointer = -1
                    state = .noScheme
                } else {
                    throw .invalidScheme(buffer)
                }

            case .noScheme:
                guard let base = context.base else {
                    throw .invalidStructure("No scheme and no base URL")
                }

                url.scheme = base.scheme

                if c == nil {
                    self = base
                    return
                } else if c == ASCII.Code.slash.byte {

                    url.host = base.host
                    url.port = base.port
                    state = .pathStart
                } else if c == ASCII.Code.questionMark.byte {
                    url.host = base.host
                    url.port = base.port
                    url.path = base.path
                    state = .query
                } else if c == ASCII.Code.numberSign.byte {
                    url.host = base.host
                    url.port = base.port
                    url.path = base.path
                    url.query = base.query
                    state = .fragment
                } else {
                    url.host = base.host
                    url.port = base.port
                    url.path = base.path
                    state = .relativePath
                    pointer -= 1
                }

            case .specialAuthoritySlashes:
                if c == ASCII.Code.slash.byte && trimmed.indices.contains(pointer + 1)
                    && trimmed[pointer + 1] == ASCII.Code.slash.byte
                {
                    state = .authority
                    pointer += 1
                } else {
                    throw .invalidStructure("Missing // after special scheme")
                }

            case .pathOrAuthority:
                if c == ASCII.Code.slash.byte {
                    state = .authority
                } else {
                    state = .path
                    pointer -= 1
                }

            case .authority:
                if c == ASCII.Code.commercialAt.byte {
                    if atSignSeen {
                        buffer = "%40" + buffer
                    }
                    atSignSeen = true

                    if let colonIndex = buffer.firstIndex(of: ":") {
                        url.username = WHATWG_URL.PercentEncoding.encode(
                            String(buffer[..<colonIndex]),
                            using: .userinfo
                        )
                        url.password = WHATWG_URL.PercentEncoding.encode(
                            String(buffer[buffer.index(after: colonIndex)...]),
                            using: .userinfo
                        )
                    } else {
                        url.username = WHATWG_URL.PercentEncoding.encode(buffer, using: .userinfo)
                    }
                    buffer = ""
                } else if c == nil || c == ASCII.Code.slash.byte
                    || c == ASCII.Code.questionMark.byte || c == ASCII.Code.numberSign.byte
                {
                    pointer -= buffer.count + 1
                    buffer = ""
                    state = .host
                } else {
                    buffer.append(Character(UnicodeScalar(c!.bitPattern)))
                }

            case .host:

                var insideBrackets = false
                while pointer < trimmed.count {
                    let ch = trimmed[pointer]
                    if ch == ASCII.Code.leftSquareBracket.byte {
                        insideBrackets = true
                    } else if ch == ASCII.Code.rightSquareBracket.byte {
                        insideBrackets = false
                    }

                    if !insideBrackets
                        && (ch == ASCII.Code.colon.byte || ch == ASCII.Code.slash.byte
                            || ch == ASCII.Code.questionMark.byte
                            || ch == ASCII.Code.numberSign.byte)
                    {
                        break
                    }
                    buffer.append(Character(UnicodeScalar(ch.bitPattern)))
                    pointer += 1
                }

                let hostContext: Host.Context =
                    Scheme.isSpecial(url.scheme!) ? .special : .nonSpecial
                do throws(Host.Error) {
                    url.host = try Host(ascii: [Byte](utf8: buffer), in: hostContext)
                } catch {
                    throw .invalidHost(error)
                }
                buffer = ""

                if pointer < trimmed.count && trimmed[pointer] == ASCII.Code.colon.byte {
                    state = .port
                } else {
                    state = .pathStart
                    pointer -= 1
                }

            case .port:
                if let ch = c, ch.bitPattern.ascii.isDigit {
                    buffer.append(Character(UnicodeScalar(ch.bitPattern)))
                } else {
                    if !buffer.isEmpty {
                        guard let port = UInt16(buffer) else {
                            throw .invalidPort(buffer)
                        }

                        let defaultPort = Scheme.defaultPort(for: url.scheme!)
                        if port != defaultPort {
                            url.port = port
                        }
                        buffer = ""
                    }
                    state = .pathStart
                    pointer -= 1
                }

            case .pathStart:
                state = .path
                if c != ASCII.Code.slash.byte {
                    pointer -= 1
                }

            case .path:
                if c == nil || c == ASCII.Code.slash.byte || c == ASCII.Code.questionMark.byte
                    || c == ASCII.Code.numberSign.byte
                {
                    if !buffer.isEmpty {
                        let decoded = WHATWG_URL.PercentEncoding.decode(buffer)

                        if decoded == ".." {
                            url.popPathSegment()
                        } else if decoded != "." {
                            url.pushPathSegment(decoded)
                        }
                        buffer = ""
                    }

                    if c == ASCII.Code.slash.byte {

                    } else if c == ASCII.Code.questionMark.byte {
                        state = .query
                    } else if c == ASCII.Code.numberSign.byte {
                        state = .fragment
                    } else {

                        break parsing
                    }
                } else {
                    buffer.append(Character(UnicodeScalar(c!.bitPattern)))
                }

            case .relativePath:
                state = .path
                if c != ASCII.Code.slash.byte {
                    if case .list(var segments) = url.path {
                        if !segments.isEmpty {
                            segments.removeLast()
                        }
                        url.path = .list(segments)
                    }
                    pointer -= 1
                }

            case .opaquePath:
                while pointer < trimmed.count {
                    let ch = trimmed[pointer]
                    if ch == ASCII.Code.questionMark.byte || ch == ASCII.Code.numberSign.byte {
                        break
                    }
                    buffer.append(Character(UnicodeScalar(ch.bitPattern)))
                    pointer += 1
                }

                url.path = .opaque(buffer)
                buffer = ""

                if pointer < trimmed.count {
                    let ch = trimmed[pointer]
                    if ch == ASCII.Code.questionMark.byte {
                        state = .query
                    } else if ch == ASCII.Code.numberSign.byte {
                        state = .fragment
                    }
                } else {

                    break parsing
                }

            case .query:
                while pointer < trimmed.count {
                    let ch = trimmed[pointer]
                    if ch == ASCII.Code.numberSign.byte {
                        break
                    }
                    buffer.append(Character(UnicodeScalar(ch.bitPattern)))
                    pointer += 1
                }

                url.query = WHATWG_URL.PercentEncoding.encode(buffer, using: .query)
                buffer = ""

                if pointer < trimmed.count && trimmed[pointer] == ASCII.Code.numberSign.byte {
                    state = .fragment

                } else {

                    break parsing
                }

            case .fragment:
                while pointer < trimmed.count {
                    buffer.append(Character(UnicodeScalar(trimmed[pointer].bitPattern)))
                    pointer += 1
                }

                url.fragment = WHATWG_URL.PercentEncoding.encode(buffer, using: .fragment)
                buffer = ""

                break parsing
            }

            pointer += 1
        }

        self = try url.build()
    }
}

extension WHATWG_URL.URL {

    public init(_ string: some StringProtocol, base: WHATWG_URL.URL? = nil) throws(Error) {
        try self.init(ascii: [Byte](utf8: String(string)), in: ParsingContext(base: base))
    }

    public init?(parsing string: some StringProtocol, base: WHATWG_URL.URL? = nil) {
        do throws(Error) {
            try self.init(string, base: base)
        } catch {
            return nil
        }
    }
}
