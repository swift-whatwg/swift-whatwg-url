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
    /// A URL scheme per WHATWG URL Standard
    ///
    /// Schemes are ASCII strings that identify the type of URL.
    /// Per the standard, schemes are:
    /// - Case-insensitive (normalized to lowercase)
    /// - Must start with ASCII alpha
    /// - Followed by ASCII alphanumeric, +, -, or .
    ///
    /// ## Special Schemes
    ///
    /// Some schemes are "special" and have additional parsing rules:
    /// - ftp, file, http, https, ws, wss
    public struct Scheme: Hashable, Sendable {
        /// The normalized (lowercase) scheme string
        public let value: String

        /// Creates a scheme without validation (for known-valid constants)
        private init(__unchecked: Void, value: String) {
            self.value = value
        }

        /// Creates a scheme with validation and normalization
        ///
        /// Per WHATWG URL Standard, a valid scheme:
        /// - Starts with ASCII alpha
        /// - Followed by ASCII alphanumeric, +, -, or .
        /// - Normalized to lowercase
        ///
        /// - Parameter value: The scheme string to validate
        /// - Throws: `Error` if the scheme is invalid
        public init(_ value: some StringProtocol) throws(Error) {
            guard !value.isEmpty else {
                throw .emptyScheme
            }

            let chars = Array(value.utf8)

            // First character must be ASCII alpha
            guard chars[0].ascii.isLetter else {
                throw .mustStartWithAlpha(Character(UnicodeScalar(chars[0])))
            }

            // Remaining characters must be ASCII alphanumeric, +, -, or .
            for byte in chars.dropFirst() {
                let isValid =
                    byte.ascii.isAlphanumeric || byte == UInt8.ascii.plus
                    || byte == UInt8.ascii.hyphen || byte == UInt8.ascii.period

                guard isValid else {
                    throw .invalidCharacter(Character(UnicodeScalar(byte)))
                }
            }

            self.init(__unchecked: (), value: value.lowercased())
        }
    }
}

// MARK: - Special Schemes

extension WHATWG_URL.URL.Scheme {
    /// Special schemes with their default ports
    private static let specialSchemes: [String: UInt16?] = [
        "ftp": 21,
        "file": nil,
        "http": 80,
        "https": 443,
        "ws": 80,
        "wss": 443,
    ]

    /// Checks if a scheme is a special scheme
    public static func isSpecial(_ scheme: Self) -> Bool {
        specialSchemes.keys.contains(scheme.value)
    }

    /// Returns the default port for a scheme, or nil if not special or has no default port
    public static func defaultPort(for scheme: Self) -> UInt16? {
        specialSchemes[scheme.value] ?? nil
    }
}

// MARK: - Common Schemes (compile-time constants)

extension WHATWG_URL.URL.Scheme {
    public static let http = Self(__unchecked: (), value: "http")
    public static let https = Self(__unchecked: (), value: "https")
    public static let file = Self(__unchecked: (), value: "file")
    public static let ftp = Self(__unchecked: (), value: "ftp")
    public static let ws = Self(__unchecked: (), value: "ws")
    public static let wss = Self(__unchecked: (), value: "wss")
}

// MARK: - Binary.ASCII.Serializable

extension WHATWG_URL.URL.Scheme: Binary.ASCII.Serializable {
    /// Serialize the scheme into an ASCII byte buffer
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii scheme: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == UInt8 {
        buffer.append(contentsOf: scheme.value.utf8)
    }

    /// Parse a scheme from ASCII bytes
    ///
    /// Delegates to public throwing init per SAFE-1c pattern.
    public init<Bytes: Collection>(
        ascii bytes: Bytes,
        in context: Void
    ) throws(Error) where Bytes.Element == UInt8 {
        try self.init(String(decoding: bytes, as: UTF8.self))
    }
}

// MARK: - CustomStringConvertible

extension WHATWG_URL.URL.Scheme: CustomStringConvertible {}
