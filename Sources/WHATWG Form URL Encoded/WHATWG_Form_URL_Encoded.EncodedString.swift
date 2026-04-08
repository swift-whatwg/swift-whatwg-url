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

public import ASCII_Serializer_Primitives

extension WHATWG_Form_URL_Encoded {
    /// A percent-encoded string per WHATWG URL Standard Section 5
    ///
    /// This type wraps an already-encoded string, providing type safety
    /// to distinguish encoded strings from plain strings.
    ///
    /// ## Creation
    ///
    /// ```swift
    /// // From plain string (encodes it)
    /// let encoded = EncodedString(encoding: "Hello World!")
    /// print(encoded.rawValue)  // "Hello+World%21"
    ///
    /// // From already-encoded string (unchecked)
    /// let trusted = EncodedString(__unchecked: "already%20encoded")
    /// ```
    ///
    /// ## Decoding
    ///
    /// ```swift
    /// let decoded = try encoded.decoded()  // "Hello World!"
    /// ```
    public struct EncodedString: Hashable, Sendable, CustomStringConvertible {
        /// The percent-encoded string value
        public let rawValue: String

        /// Creates from an already percent-encoded string without validation
        ///
        /// Use this initializer when you have a string that is known to be
        /// correctly percent-encoded, such as from a trusted source.
        ///
        /// - Parameter rawValue: An already percent-encoded string
        /// - Warning: No validation is performed. Use only with trusted input.
        public init(__unchecked rawValue: String) {
            self.rawValue = rawValue
        }

        /// Creates by encoding a plain string
        ///
        /// - Parameters:
        ///   - string: The plain string to encode
        ///   - spaceAsPlus: If true, space encoded as '+', otherwise '%20'
        public init(encoding string: String, spaceAsPlus: Bool = true) {
            self.rawValue = PercentEncoding.encode(string, spaceAsPlus: spaceAsPlus)
        }

        /// Decodes to a plain string
        ///
        /// - Parameter plusAsSpace: If true, '+' decoded as space (0x20)
        /// - Returns: The decoded string
        /// - Throws: `PercentEncoding.Error` if the encoding is invalid
        public func decoded(plusAsSpace: Bool = true) throws(PercentEncoding.Error) -> String {
            try PercentEncoding.decode(rawValue, plusAsSpace: plusAsSpace)
        }

        /// The percent-encoded string value
        public var description: String {
            rawValue
        }
    }
}

// MARK: - Binary.ASCII.Serializable Conformance

extension WHATWG_Form_URL_Encoded.EncodedString: Binary.ASCII.Serializable {
    /// Serialize the encoded string into an ASCII byte buffer
    ///
    /// Simply writes the UTF-8 bytes of the encoded string.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii instance: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == UInt8 {
        buffer.append(contentsOf: instance.rawValue.utf8)
    }

    /// Parse from ASCII bytes
    ///
    /// The bytes are interpreted as a percent-encoded string.
    /// No validation is performed - use `decoded()` to validate.
    public init<Bytes: Collection>(
        ascii bytes: Bytes,
        in context: Void
    ) throws(WHATWG_Form_URL_Encoded.PercentEncoding.Error) where Bytes.Element == UInt8 {
        let string = String(decoding: bytes, as: UTF8.self)
        self.init(__unchecked: string)
    }

    public typealias Error = WHATWG_Form_URL_Encoded.PercentEncoding.Error
}

// MARK: - ExpressibleByStringLiteral

extension WHATWG_Form_URL_Encoded.EncodedString: ExpressibleByStringLiteral {
    /// Creates an encoded string from a string literal
    ///
    /// The literal is treated as an already-encoded string (unchecked).
    /// Use `EncodedString(encoding:)` to encode a plain string.
    public init(stringLiteral value: String) {
        self.init(__unchecked: value)
    }
}
