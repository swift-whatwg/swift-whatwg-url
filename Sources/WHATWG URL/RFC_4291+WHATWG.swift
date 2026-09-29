public import RFC_4291
import Byte
import RFC_791

extension RFC_4291.IPv6.Address {

    public init?(whatwgString: String) {
        var input = whatwgString

        if input.hasPrefix("[") && input.hasSuffix("]") {
            input = String(input.dropFirst().dropLast())
        }

        if let percentIndex = input.firstIndex(of: "%") {
            input = String(input[..<percentIndex])
        }

        guard let addr = Self.parseRFC4291(input) else {
            return nil
        }

        self = addr
    }

    private static func parseRFC4291(_ string: String) -> Self? {

        if let colonIndex = string.lastIndex(of: ":"),
            string[string.index(after: colonIndex)...].contains(".")
        {
            return parseIPv4Embedded(string)
        }

        let parts = string.split(separator: ":", omittingEmptySubsequences: false)

        let compressionIndex = parts.firstIndex(where: { $0.isEmpty })

        var pieces: [UInt16] = []
        var beforeCompression: [UInt16] = []
        var afterCompression: [UInt16] = []

        if let compIdx = compressionIndex {

            for part in parts[0..<compIdx] {
                guard let piece = UInt16(part, radix: 16), part.count <= 4 else {
                    return nil
                }
                beforeCompression.append(piece)
            }

            var skipEmpty = true
            for part in parts[(compIdx + 1)...] {
                if part.isEmpty && skipEmpty {
                    continue
                }
                skipEmpty = false

                guard !part.isEmpty else { return nil }
                guard let piece = UInt16(part, radix: 16), part.count <= 4 else {
                    return nil
                }
                afterCompression.append(piece)
            }

            let totalPieces = beforeCompression.count + afterCompression.count
            guard totalPieces < 8 else { return nil }

            let zerosCount = 8 - totalPieces
            pieces = beforeCompression + Array(repeating: 0, count: zerosCount) + afterCompression

        } else {

            guard parts.count == 8 else { return nil }

            for part in parts {
                guard let piece = UInt16(part, radix: 16), part.count <= 4 else {
                    return nil
                }
                pieces.append(piece)
            }
        }

        guard pieces.count == 8 else { return nil }

        return Self(
            pieces[0],
            pieces[1],
            pieces[2],
            pieces[3],
            pieces[4],
            pieces[5],
            pieces[6],
            pieces[7]
        )
    }

    private static func parseIPv4Embedded(_ string: String) -> Self? {
        guard let lastColon = string.lastIndex(of: ":") else {
            return nil
        }

        let ipv6Part = String(string[..<lastColon])
        let ipv4Part = String(string[string.index(after: lastColon)...])

        guard let ipv4 = RFC_791.IPv4.Address(whatwgString: ipv4Part) else {
            return nil
        }

        let parts = ipv6Part.split(separator: ":", omittingEmptySubsequences: false)

        var pieces: [UInt16] = []
        var compressionSeen = false

        for part in parts {
            if part.isEmpty {
                if !compressionSeen {

                    compressionSeen = true
                    let remainingParts = parts.dropFirst(pieces.count + 1).filter { !$0.isEmpty }
                        .count
                    let zerosCount = 6 - pieces.count - remainingParts
                    if zerosCount > 0 {
                        pieces.append(contentsOf: Array(repeating: 0, count: zerosCount))
                    }
                }

            } else {
                guard let piece = UInt16(part, radix: 16), part.count <= 4 else {
                    return nil
                }
                pieces.append(piece)
            }
        }

        guard pieces.count == 6 else { return nil }

        let octets = ipv4.octets
        let piece6 = UInt16(octets.0.bitPattern) << 8 | UInt16(octets.1.bitPattern)
        let piece7 = UInt16(octets.2.bitPattern) << 8 | UInt16(octets.3.bitPattern)

        pieces.append(piece6)
        pieces.append(piece7)

        return Self(
            pieces[0],
            pieces[1],
            pieces[2],
            pieces[3],
            pieces[4],
            pieces[5],
            pieces[6],
            pieces[7]
        )
    }
}
