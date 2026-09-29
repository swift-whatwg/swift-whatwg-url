import ASCII
import Byte
import Byte

extension WHATWG_Form_URL_Encoded {

    public enum PercentEncoding {}
}

extension WHATWG_Form_URL_Encoded.PercentEncoding {

    public static func encode(
        _ string: String,
        space: WHATWG_Form_URL_Encoded.SpaceEncoding = .plus
    ) -> String {
        var result = ""

        for byte in [Byte](utf8: string) {
            switch byte {

            case _ where byte.bitPattern.ascii.isAlphanumeric:
                result.append(Character(UnicodeScalar(byte.bitPattern)))

            case ASCII.Code.asterisk.byte,
                ASCII.Code.hyphen.byte,
                ASCII.Code.period.byte,
                ASCII.Code.underline.byte:
                result.append(Character(UnicodeScalar(byte.bitPattern)))

            case ASCII.Code.sp.byte:
                result.append(space == .plus ? "+" : "%20")

            default:

                result.append("%")
                result.append(hexDigit(byte.bitPattern >> 4))
                result.append(hexDigit(byte.bitPattern & 0x0F))
            }
        }

        return result
    }

    private static func hexDigit(_ nibble: UInt8) -> Character {
        Character(UnicodeScalar(ASCII.Hexadecimal.code(nibble, case: .upper)!.underlying))
    }
}

extension WHATWG_Form_URL_Encoded.PercentEncoding {

    public static func decode(
        _ string: String,
        space: WHATWG_Form_URL_Encoded.SpaceEncoding = .plus
    ) throws(Error) -> String {
        var bytes: [Byte] = []
        var index = string.startIndex

        while index < string.endIndex {
            let char = string[index]

            if char == "+" && space == .plus {
                bytes.append(ASCII.Code.sp.byte)
                index = string.index(after: index)
            } else if char == "%" {

                let nextIndex = string.index(after: index)
                guard nextIndex < string.endIndex else {
                    throw .unexpectedEndOfInput
                }

                let secondIndex = string.index(after: nextIndex)
                guard secondIndex < string.endIndex else {
                    throw .unexpectedEndOfInput
                }

                let hexString = String(string[nextIndex...secondIndex])
                guard let byte = UInt8(hexString, radix: 16) else {
                    throw .invalidPercentEncoding(
                        position: string.distance(from: string.startIndex, to: index),
                        found: "%" + hexString
                    )
                }

                bytes.append(Byte(bitPattern: byte))
                index = string.index(after: secondIndex)
            } else {
                bytes.append(contentsOf: [Byte](utf8: String(char)))
                index = string.index(after: index)
            }
        }

        return String(decoding: bytes, as: UTF8.self)
    }

    public static func decodeOrNil(
        _ string: String,
        space: WHATWG_Form_URL_Encoded.SpaceEncoding = .plus
    ) -> String? {
        do throws(Error) {
            return try decode(string, space: space)
        } catch {
            return nil
        }
    }
}
