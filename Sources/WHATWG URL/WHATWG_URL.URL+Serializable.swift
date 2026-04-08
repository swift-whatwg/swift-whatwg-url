// ===----------------------------------------------------------------------===//
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of project contributors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import Domain_Standard
public import ASCII_Serializer_Primitives
import RFC_5952
import RFC_791

// MARK: - Context for URL Parsing

extension WHATWG_URL.URL {
    /// Context for parsing a URL
    public struct ParsingContext: Sendable {
        /// Optional base URL for relative URL resolution
        public let base: WHATWG_URL.URL?

        public init(base: WHATWG_URL.URL? = nil) {
            self.base = base
        }

        /// Context without a base URL
        public static let none = ParsingContext(base: nil)
    }
}

// MARK: - Parser State Machine

extension WHATWG_URL.URL {
    /// Parser states for the URL parsing state machine
    fileprivate enum State {
        case schemeStart
        case scheme
        case noScheme
        case specialAuthoritySlashes
        case pathOrAuthority
        case authority
        case host
        case port
        case pathStart
        case path
        case relativePath
        case opaquePath
        case query
        case fragment
    }

    /// Internal builder for constructing URLs during parsing
    fileprivate struct Builder {
        var scheme: Scheme?
        var username: String = ""
        var password: String = ""
        var host: Host?
        var port: UInt16?
        var path: Path = .list([])
        var query: String?
        var fragment: String?

        mutating func pushPathSegment(_ segment: String) {
            switch path {
            case .list(var segments):
                segments.append(segment)
                path = .list(segments)
            case .opaque:
                break
            }
        }

        mutating func popPathSegment() {
            switch path {
            case .list(var segments):
                if !segments.isEmpty {
                    segments.removeLast()
                }
                path = .list(segments)
            case .opaque:
                break
            }
        }

        func build() throws(Error) -> WHATWG_URL.URL {
            guard let scheme = scheme else {
                throw .invalidScheme("")
            }

            return WHATWG_URL.URL(
                scheme: scheme,
                username: username,
                password: password,
                host: host,
                port: port,
                path: path,
                query: query,
                fragment: fragment
            )
        }
    }
}

// MARK: - Binary.ASCII.Serializable Conformance

extension WHATWG_URL.URL: Binary.ASCII.Serializable {
    public typealias Context = WHATWG_URL.URL.ParsingContext

    /// Serialize the URL into an ASCII byte buffer
    ///
    /// Per WHATWG URL Standard Section 4.5: URL Serializing
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii url: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == UInt8 {
        // Scheme
        Scheme.serialize(ascii: url.scheme, into: &buffer)
        buffer.append(UInt8.ascii.colon)

        // Authority (if host present)
        if let host = url.host {
            buffer.append(UInt8.ascii.slash)
            buffer.append(UInt8.ascii.slash)

            // Username/Password
            if !url.username.isEmpty || !url.password.isEmpty {
                buffer.append(contentsOf: url.username.utf8)
                if !url.password.isEmpty {
                    buffer.append(UInt8.ascii.colon)
                    buffer.append(contentsOf: url.password.utf8)
                }
                buffer.append(UInt8.ascii.commercialAt)
            }

            // Host
            Host.serialize(ascii: host, into: &buffer)

            // Port (omit if it's the default for this scheme)
            if let port = url.port, Scheme.defaultPort(for: url.scheme) != port {
                buffer.append(UInt8.ascii.colon)
                buffer.append(contentsOf: String(port).utf8)
            }
        }

        // Path
        Path.serialize(ascii: url.path, into: &buffer)

        // Query
        if let query = url.query {
            buffer.append(UInt8.ascii.questionMark)
            buffer.append(contentsOf: query.utf8)
        }

        // Fragment
        if let fragment = url.fragment {
            buffer.append(UInt8.ascii.numberSign)
            buffer.append(contentsOf: fragment.utf8)
        }
    }

    /// Parse a URL from ASCII bytes
    ///
    /// Per WHATWG URL Standard Section 4.3: Basic URL Parser
    public init<Bytes: Collection>(
        ascii bytes: Bytes,
        in context: Context
    ) throws(Error) where Bytes.Element == UInt8 {
        var url = Builder()
        var state = State.schemeStart
        var buffer = ""
        var atSignSeen = false

        let array = Array(bytes)

        // Trim leading/trailing whitespace (space and horizontal tab)
        let horizontalTab: UInt8 = 0x09
        var startIndex = 0
        var endIndex = array.count
        while startIndex < endIndex
            && (array[startIndex] == UInt8.ascii.sp || array[startIndex] == horizontalTab) {
            startIndex += 1
        }
        while endIndex > startIndex
            && (array[endIndex - 1] == UInt8.ascii.sp || array[endIndex - 1] == horizontalTab) {
            endIndex -= 1
        }

        let trimmed = Array(array[startIndex..<endIndex])

        guard !trimmed.isEmpty else {
            // Empty input with base URL returns the base URL
            if let base = context.base {
                self = base
                return
            }
            throw .emptyInput
        }

        var pointer = 0

        parsing: while pointer <= trimmed.count {
            let c: UInt8? = pointer < trimmed.count ? trimmed[pointer] : nil

            switch state {
            case .schemeStart:
                if let ch = c, ch.ascii.isLetter {
                    buffer.append(Character(UnicodeScalar(ch)).lowercased())
                    state = .scheme
                } else if context.base != nil {
                    state = .noScheme
                    pointer -= 1
                } else {
                    throw .invalidScheme(String(decoding: trimmed, as: UTF8.self))
                }

            case .scheme:
                if let ch = c,
                    ch.ascii.isAlphanumeric || ch == UInt8.ascii.plus || ch == UInt8.ascii.hyphen
                        || ch == UInt8.ascii.period {
                    buffer.append(Character(UnicodeScalar(ch)).lowercased())
                } else if c == UInt8.ascii.colon {
                    do {
                        url.scheme = try Scheme(buffer)
                    } catch {
                        throw .invalidScheme(buffer)
                    }
                    buffer = ""

                    if Scheme.isSpecial(url.scheme!) {
                        state = .specialAuthoritySlashes
                    } else if pointer + 1 < trimmed.count
                        && trimmed[pointer + 1] == UInt8.ascii.slash {
                        state = .pathOrAuthority
                        pointer += 1
                    } else {
                        state = .opaquePath
                    }
                } else if context.base != nil {
                    // Not a valid scheme character - backtrack and treat as relative URL
                    buffer = ""
                    pointer = -1  // Will be incremented to 0 by main loop
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
                } else if c == UInt8.ascii.slash {
                    // Absolute path - use base's host and port
                    url.host = base.host
                    url.port = base.port
                    state = .pathStart
                } else if c == UInt8.ascii.questionMark {
                    url.host = base.host
                    url.port = base.port
                    url.path = base.path
                    state = .query
                } else if c == UInt8.ascii.numberSign {
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
                if c == UInt8.ascii.slash && pointer + 1 < trimmed.count
                    && trimmed[pointer + 1] == UInt8.ascii.slash {
                    state = .authority
                    pointer += 1
                } else {
                    throw .invalidStructure("Missing // after special scheme")
                }

            case .pathOrAuthority:
                if c == UInt8.ascii.slash {
                    state = .authority
                } else {
                    state = .path
                    pointer -= 1
                }

            case .authority:
                if c == UInt8.ascii.commercialAt {
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
                } else if c == nil || c == UInt8.ascii.slash || c == UInt8.ascii.questionMark
                    || c == UInt8.ascii.numberSign {
                    pointer -= buffer.count + 1
                    buffer = ""
                    state = .host
                } else {
                    buffer.append(Character(UnicodeScalar(c!)))
                }

            case .host:
                // Handle IPv6 addresses in brackets specially - don't stop at colons inside brackets
                var insideBrackets = false
                while pointer < trimmed.count {
                    let ch = trimmed[pointer]
                    if ch == UInt8.ascii.leftSquareBracket {
                        insideBrackets = true
                    } else if ch == UInt8.ascii.rightSquareBracket {
                        insideBrackets = false
                    }
                    // Only break on : if not inside brackets
                    if !insideBrackets
                        && (ch == UInt8.ascii.colon || ch == UInt8.ascii.slash
                            || ch == UInt8.ascii.questionMark || ch == UInt8.ascii.numberSign) {
                        break
                    }
                    buffer.append(Character(UnicodeScalar(ch)))
                    pointer += 1
                }

                let isSpecial = Scheme.isSpecial(url.scheme!)
                let hostContext = Host.Context(isSpecial: isSpecial)
                do {
                    url.host = try Host(ascii: Array(buffer.utf8), in: hostContext)
                } catch let hostError as Host.Error {
                    throw .invalidHost(hostError)
                } catch {
                    throw .invalidHost(.invalidDomain(buffer))
                }
                buffer = ""

                if pointer < trimmed.count && trimmed[pointer] == UInt8.ascii.colon {
                    state = .port
                } else {
                    state = .pathStart
                    pointer -= 1
                }

            case .port:
                if let ch = c, ch.ascii.isDigit {
                    buffer.append(Character(UnicodeScalar(ch)))
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
                if c != UInt8.ascii.slash {
                    pointer -= 1
                }

            case .path:
                if c == nil || c == UInt8.ascii.slash || c == UInt8.ascii.questionMark
                    || c == UInt8.ascii.numberSign {
                    if !buffer.isEmpty {
                        let decoded = WHATWG_URL.PercentEncoding.decode(buffer)

                        if decoded == ".." {
                            url.popPathSegment()
                        } else if decoded != "." {
                            url.pushPathSegment(decoded)
                        }
                        buffer = ""
                    }

                    if c == UInt8.ascii.slash {
                        // Continue path
                    } else if c == UInt8.ascii.questionMark {
                        state = .query
                    } else if c == UInt8.ascii.numberSign {
                        state = .fragment
                    } else {
                        // End of input - exit the parsing loop
                        break parsing
                    }
                } else {
                    buffer.append(Character(UnicodeScalar(c!)))
                }

            case .relativePath:
                state = .path
                if c != UInt8.ascii.slash {
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
                    if ch == UInt8.ascii.questionMark || ch == UInt8.ascii.numberSign {
                        break
                    }
                    buffer.append(Character(UnicodeScalar(ch)))
                    pointer += 1
                }

                // Opaque paths preserve most characters as-is (only C0 controls need encoding)
                url.path = .opaque(buffer)
                buffer = ""

                if pointer < trimmed.count {
                    let ch = trimmed[pointer]
                    if ch == UInt8.ascii.questionMark {
                        state = .query
                    } else if ch == UInt8.ascii.numberSign {
                        state = .fragment
                    }
                } else {
                    // End of input
                    break parsing
                }

            case .query:
                while pointer < trimmed.count {
                    let ch = trimmed[pointer]
                    if ch == UInt8.ascii.numberSign {
                        break
                    }
                    buffer.append(Character(UnicodeScalar(ch)))
                    pointer += 1
                }

                url.query = WHATWG_URL.PercentEncoding.encode(buffer, using: .query)
                buffer = ""

                if pointer < trimmed.count && trimmed[pointer] == UInt8.ascii.numberSign {
                    state = .fragment
                    // Main loop's pointer += 1 will skip the '#'
                } else {
                    // End of input
                    break parsing
                }

            case .fragment:
                while pointer < trimmed.count {
                    buffer.append(Character(UnicodeScalar(trimmed[pointer])))
                    pointer += 1
                }

                url.fragment = WHATWG_URL.PercentEncoding.encode(buffer, using: .fragment)
                buffer = ""
                // End of input - fragment is always the final state
                break parsing
            }

            pointer += 1
        }

        self = try url.build()
    }
}

// MARK: - Convenience Initializers

extension WHATWG_URL.URL {
    /// Parse a URL from a string
    ///
    /// - Parameter string: The string to parse
    /// - Parameter base: Optional base URL for relative URL resolution
    /// - Throws: `Error` if the string is not a valid URL
    public init(_ string: some StringProtocol, base: WHATWG_URL.URL? = nil) throws(Error) {
        try self.init(ascii: Array(string.utf8), in: ParsingContext(base: base))
    }

    /// Parse a URL from a string, returning nil on failure
    ///
    /// - Parameter string: The string to parse
    /// - Parameter base: Optional base URL for relative URL resolution
    /// - Returns: Parsed URL, or nil if invalid
    public init?(parsing string: some StringProtocol, base: WHATWG_URL.URL? = nil) {
        do {
            try self.init(string, base: base)
        } catch {
            return nil
        }
    }
}

// MARK: - CustomStringConvertible

extension WHATWG_URL.URL: CustomStringConvertible {
    public var description: String {
        String(ascii: self)
    }
}
