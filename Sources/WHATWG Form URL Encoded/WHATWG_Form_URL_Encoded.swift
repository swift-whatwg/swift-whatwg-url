public enum WHATWG_Form_URL_Encoded {}

extension WHATWG_Form_URL_Encoded {

    public static func serialize(_ pairs: [(String, String)]) -> String {
        pairs
            .map { name, value in
                let encodedName = PercentEncoding.encode(name, space: .plus)
                let encodedValue = PercentEncoding.encode(value, space: .plus)
                return "\(encodedName)=\(encodedValue)"
            }
            .joined(separator: "&")
    }

    public static func parse(_ input: String) -> [(String, String)] {

        guard !input.isEmpty else { return [] }

        return
            input
            .split(separator: "&", omittingEmptySubsequences: false)
            .compactMap { pair in

                guard !pair.isEmpty else { return nil }

                let components = pair.split(
                    separator: "=",
                    maxSplits: 1,
                    omittingEmptySubsequences: false
                )
                guard !components.isEmpty else { return nil }

                let name = String(components[0])
                let value = components.count > 1 ? String(components[1]) : ""

                guard let decodedName = PercentEncoding.decodeOrNil(name, space: .plus),
                    let decodedValue = PercentEncoding.decodeOrNil(value, space: .plus)
                else {
                    return nil
                }

                return (decodedName, decodedValue)
            }
    }
}
