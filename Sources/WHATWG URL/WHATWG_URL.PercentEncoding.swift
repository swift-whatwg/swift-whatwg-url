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

import ASCII

extension WHATWG_URL {
    /// Percent-encoding utilities per WHATWG URL Standard Section 1.3
    ///
    /// Percent-encoding (also known as URL encoding) is used to encode special
    /// characters in URLs using the format %XX where XX is the hexadecimal
    /// representation of the byte.
    enum PercentEncoding {}
}

// MARK: - Hex Digit Helper

extension WHATWG_URL.PercentEncoding {
    /// Convert a nibble (0-15) to its uppercase hex character
    @inline(always)
    private static func hexDigit(_ nibble: UInt8) -> String {
        let chars: [Character] = [
            "0", "1", "2", "3", "4", "5", "6", "7",
            "8", "9", "A", "B", "C", "D", "E", "F",
        ]
        return String(chars[Int(nibble & 0x0F)])
    }
}

// MARK: - Percent Decode

extension WHATWG_URL.PercentEncoding {
    /// Percent-decode a string
    ///
    /// Per WHATWG URL Standard Section 1.3, percent-decoding:
    /// 1. Replace each %XX sequence with the byte value it represents
    /// 2. Interpret the resulting bytes as UTF-8
    ///
    /// - Parameter input: The percent-encoded string
    /// - Returns: Decoded string
    static func decode(_ input: String) -> String {
        var result = ""
        var chars = Array(input)
        var i = 0

        while i < chars.count {
            if chars[i] == "%", i + 2 < chars.count {
                // Try to decode %XX
                let hex = String(chars[i + 1...i + 2])
                if let byte = UInt8(hex, radix: 16) {
                    // Collect consecutive percent-encoded bytes
                    var bytes: [UInt8] = [byte]
                    i += 3

                    while i < chars.count && chars[i] == "%", i + 2 < chars.count {
                        let nextHex = String(chars[i + 1...i + 2])
                        if let nextByte = UInt8(nextHex, radix: 16) {
                            bytes.append(nextByte)
                            i += 3
                        } else {
                            break
                        }
                    }

                    // Decode as UTF-8
                    let decoded = String(decoding: bytes, as: UTF8.self)
                    // Check if decoding was lossless (no replacement characters introduced)
                    if decoded.utf8.elementsEqual(bytes) {
                        result += decoded
                    } else {
                        // Invalid UTF-8, keep as-is with percent encoding
                        for byte in bytes {
                            result += "%"
                            result += hexDigit(byte >> 4)
                            result += hexDigit(byte & 0x0F)
                        }
                    }
                    continue
                }
            }

            result.append(chars[i])
            i += 1
        }

        return result
    }
}

// MARK: - Percent Encode

extension WHATWG_URL.PercentEncoding {
    /// Percent-encode a string using a specific encode set
    ///
    /// - Parameters:
    ///   - input: The string to encode
    ///   - set: The encode set determining which characters to encode
    /// - Returns: Percent-encoded string
    static func encode(_ input: String, using set: EncodeSet) -> String {
        var result = ""

        for char in input {
            if set.shouldEncode(char) {
                // Encode as UTF-8 bytes
                for byte in String(char).utf8 {
                    result += "%"
                    result += hexDigit(byte >> 4)
                    result += hexDigit(byte & 0x0F)
                }
            } else {
                result.append(char)
            }
        }

        return result
    }
}

// MARK: - Encode Sets

extension WHATWG_URL.PercentEncoding {
    /// Encode sets define which characters should be percent-encoded
    ///
    /// Per WHATWG URL Standard Section 1.3
    enum EncodeSet {
        /// C0 control percent-encode set
        case c0Control

        /// Fragment percent-encode set
        case fragment

        /// Query percent-encode set
        case query

        /// Special query percent-encode set (used in special URLs)
        case specialQuery

        /// Path percent-encode set
        case path

        /// Userinfo percent-encode set
        case userinfo

        /// Component percent-encode set
        case component

        func shouldEncode(_ char: Character) -> Bool {
            let scalar = char.unicodeScalars.first!
            let value = scalar.value

            // C0 controls: U+0000 to U+001F (NUL through US)
            let isC0Control = value <= UInt32(UInt8.ascii.us)

            // Non-ASCII: above tilde (0x7E)
            let isNonASCII = value > UInt32(UInt8.ascii.tilde)

            // Characters always encoded
            let alwaysEncode =
                char == " " || char == "\"" || char == "<" || char == ">" || char == "`"

            // Check specific encode set rules
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
}
