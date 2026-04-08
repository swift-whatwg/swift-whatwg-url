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

extension WHATWG_URL.URL {
    /// A hypertext reference (href) - a normalized, valid URL string
    ///
    /// An `Href` is a newtype wrapper around a String that guarantees:
    /// - The string is a valid URL (parseable per WHATWG URL Standard)
    /// - The string is normalized (serialized per Section 4.5)
    /// - The string represents a complete URL
    ///
    /// ## Type Safety
    ///
    /// This newtype prevents invalid URL strings at compile time.
    /// Construction is only possible from a valid `WHATWG_URL.URL`.
    public struct Href: Hashable, Sendable {
        /// The normalized, valid URL string
        public let value: String

        /// Creates an Href without validation (for known-valid strings)
        private init(__unchecked: Void, value: String) {
            self.value = value
        }

        /// Creates an Href from a validated URL
        ///
        /// This is the core initializer - always succeeds because the URL is already valid.
        /// Uses `Binary.ASCII.Serializable` to serialize the URL to its canonical form.
        public init(_ url: WHATWG_URL.URL) {
            self.init(__unchecked: (), value: String(ascii: url))
        }
    }
}

// MARK: - Binary.ASCII.Serializable

extension WHATWG_URL.URL.Href: Binary.ASCII.Serializable {
    /// Serialize the href into an ASCII byte buffer
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii href: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == UInt8 {
        buffer.append(contentsOf: href.value.utf8)
    }

    /// Parse an href from ASCII bytes
    ///
    /// Parses the bytes as a URL, then creates an Href from it.
    public init<Bytes: Collection>(
        ascii bytes: Bytes,
        in context: Void
    ) throws(WHATWG_URL.URL.Error) where Bytes.Element == UInt8 {
        let url = try WHATWG_URL.URL(ascii: bytes, in: .none)
        self.init(url)
    }
}

// MARK: - CustomStringConvertible

extension WHATWG_URL.URL.Href: CustomStringConvertible {}
