//
//  WHATWG_URL.URL.Scheme.Parse.swift
//  swift-whatwg-url
//
//  WHATWG URL scheme: alpha *( alpha / digit / "+" / "-" / "." ) ":"
//

public import Parser_Primitives

extension WHATWG_URL.URL.Scheme {
    /// Parses a URL scheme per the WHATWG URL Standard.
    ///
    /// `scheme = alpha *( alpha / digit / "+" / "-" / "." )`
    ///
    /// The scheme is terminated by `:` (0x3A) which is consumed.
    /// The returned output is the raw scheme bytes (without the colon),
    /// normalized to lowercase by the caller.
    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension WHATWG_URL.URL.Scheme.Parse {
    /// Raw scheme bytes (excluding the trailing colon).
    public typealias Output = Input

    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedAlpha
        case expectedColon
    }
}

extension WHATWG_URL.URL.Scheme.Parse: Parser.`Protocol` {
    public typealias ParseOutput = Output
    public typealias Failure = WHATWG_URL.URL.Scheme.Parse<Input>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        let start = input.startIndex

        // First byte must be ASCII alpha
        guard input.startIndex < input.endIndex else { throw .expectedAlpha }
        let first = input[input.startIndex]
        guard (first >= 0x41 && first <= 0x5A)
            || (first >= 0x61 && first <= 0x7A)
        else {
            throw .expectedAlpha
        }
        input = input[input.index(after: input.startIndex)...]

        // Subsequent: alpha / digit / "+" (0x2B) / "-" (0x2D) / "." (0x2E)
        while input.startIndex < input.endIndex {
            let byte = input[input.startIndex]
            let valid = (byte >= 0x41 && byte <= 0x5A)
                || (byte >= 0x61 && byte <= 0x7A)
                || (byte >= 0x30 && byte <= 0x39)
                || byte == 0x2B || byte == 0x2D || byte == 0x2E
            guard valid else { break }
            input = input[input.index(after: input.startIndex)...]
        }

        let scheme = input[start..<input.startIndex]

        // Expect ':' (0x3A)
        guard input.startIndex < input.endIndex,
            input[input.startIndex] == 0x3A
        else {
            throw .expectedColon
        }
        input = input[input.index(after: input.startIndex)...]

        return scheme
    }
}
