import ASCII
import Byte

extension WHATWG_URL {

    enum PercentEncoding {}
}

extension WHATWG_URL.PercentEncoding {

    @inline(always)
    private static func hexDigit(_ nibble: UInt8) -> String {

        guard let code = ASCII.Hexadecimal.code(nibble & 0x0F, case: .upper) else {
            preconditionFailure("A masked nibble always has a hexadecimal digit")
        }
        return String(Character(UnicodeScalar(code.underlying)))
    }
}

extension WHATWG_URL.PercentEncoding {

    static func decode(_ input: String) -> String {
        var result = ""
        let chars = Array(input)
        var i = 0

        while i < chars.count {
            if chars[i] == "%", i + 2 < chars.count {

                let hex = String(chars[i + 1...i + 2])
                if hex.allSatisfy({ $0.isHexDigit }), let byte = UInt8(hex, radix: 16) {

                    var bytes: [Byte] = [Byte(bitPattern: byte)]
                    i += 3

                    while i < chars.count && chars[i] == "%", i + 2 < chars.count {
                        let nextHex = String(chars[i + 1...i + 2])
                        guard nextHex.allSatisfy({ $0.isHexDigit }), let nextByte = UInt8(nextHex, radix: 16) else {
                            break
                        }
                        bytes.append(Byte(bitPattern: nextByte))
                        i += 3
                    }

                    let decoded = String(decoding: bytes, as: UTF8.self)

                    if decoded.utf8.elementsEqual(bytes.lazy.map({ $0.bitPattern })) {
                        result += decoded
                    } else {

                        for byte in bytes {
                            result += "%"
                            result += hexDigit(byte.bitPattern >> 4)
                            result += hexDigit(byte.bitPattern & 0x0F)
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

extension WHATWG_URL.PercentEncoding {

    static func encode(_ input: String, using set: EncodeSet) -> String {
        var result = ""

        for char in input {
            if set.shouldEncode(char) {

                for byte in [Byte](utf8: String(char)) {
                    result += "%"
                    result += hexDigit(byte.bitPattern >> 4)
                    result += hexDigit(byte.bitPattern & 0x0F)
                }
            } else {
                result.append(char)
            }
        }

        return result
    }
}
