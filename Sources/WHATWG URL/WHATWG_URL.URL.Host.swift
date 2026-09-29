public import Byte
public import Domain_Standard
public import RFC_4291
public import RFC_791
import ASCII
import Byte
import RFC_5952

extension WHATWG_URL.URL {

    public enum Host: Hashable, Sendable {

        case domain(Domain_Standard.Domain)

        case ipv4(RFC_791.IPv4.Address)

        case ipv6(RFC_4291.IPv6.Address)

        case opaque(String)

        case empty
    }
}

extension WHATWG_URL.URL.Host {

    public init<Bytes: Swift.Collection>(
        ascii bytes: Bytes,
        in context: Context
    ) throws(Error) where Bytes.Element == Byte {
        let array = [Byte](bytes)

        guard !array.isEmpty else {
            self = .empty
            return
        }

        if array.first == ASCII.Code.leftSquareBracket.byte {
            guard array.last == ASCII.Code.rightSquareBracket.byte else {
                throw .ipv6BracketMismatch
            }

            let ipv6String = String(decoding: array, as: UTF8.self)

            if let address = RFC_4291.IPv6.Address(whatwgString: ipv6String) {
                self = .ipv6(address)
            } else {
                throw .invalidIPv6Address(ipv6String)
            }
            return
        }

        let hostString = String(decoding: array, as: UTF8.self)

        if context.kind == .special {

            let couldBeIPv4 = hostString.allSatisfy { c in
                c.isNumber || c == "." || c == "x" || c == "X" || (c >= "a" && c <= "f")
                    || (c >= "A" && c <= "F")
            }

            if couldBeIPv4, let address = RFC_791.IPv4.Address(whatwgString: hostString) {
                self = .ipv4(address)
                return
            }

            do throws(Domain_Standard.Domain.Error) {
                let domain = try Domain_Standard.Domain(hostString)
                self = .domain(domain)
            } catch {
                throw .invalidDomain(hostString)
            }
        } else {

            self = .opaque(hostString)
        }
    }
}

extension WHATWG_URL.URL.Host: CustomStringConvertible {

    public var description: String {
        switch self {
        case .domain(let domain):
            return domain.name

        case .ipv4(let address):
            return address.description

        case .ipv6(let address):
            return "[" + Self.text(address) + "]"

        case .opaque(let host):
            return host

        case .empty:
            return ""
        }
    }
}

extension WHATWG_URL.URL.Host {

    private static func text(_ address: RFC_4291.IPv6.Address) -> String {
        let segments = address.segments
        let groups: [UInt16] = [
            segments.0, segments.1, segments.2, segments.3,
            segments.4, segments.5, segments.6, segments.7,
        ]
        let compression = RFC_5952.Compression(address)

        var output = ""
        var index = 0

        while index < groups.count {
            if let compression, compression.start == index {
                output += "::"
                index = compression.end
                continue
            }

            if !output.isEmpty && !output.hasSuffix(":") {
                output += ":"
            }

            output += String(groups[index], radix: 16)
            index += 1
        }

        return output
    }
}
