import Testing

@testable import WHATWG_Form_URL_Encoded

@Suite
struct `README Verification` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `README Verification`.Unit {
    @Test
    func `Example from source: Serialize to application/x-www-form-urlencoded`() throws {
        let encoded = WHATWG_Form_URL_Encoded.serialize([
            ("name", "John Doe"),
            ("email", "john@example.com"),
        ])

        #expect(encoded == "name=John+Doe&email=john%40example.com")
    }

    @Test
    func `Example from source: Parse application/x-www-form-urlencoded`() throws {
        let pairs = WHATWG_Form_URL_Encoded.parse("name=John+Doe&email=john%40example.com")

        #expect(pairs.count == 2)
        #expect(pairs[0].0 == "name")
        #expect(pairs[0].1 == "John Doe")
        #expect(pairs[1].0 == "email")
        #expect(pairs[1].1 == "john@example.com")
    }

    @Test
    func `Example from source: Percent encode with space as plus`() throws {
        let encoded = WHATWG_Form_URL_Encoded.PercentEncoding.encode(
            "Hello World!",
            space: .plus
        )
        #expect(encoded == "Hello+World%21")
    }

    @Test
    func `Example from source: Percent decode with plus as space`() throws {
        let decoded = try WHATWG_Form_URL_Encoded.PercentEncoding.decode(
            "Hello+World%21",
            space: .plus
        )
        #expect(decoded == "Hello World!")
    }

    @Test
    func `WHATWG Character Set: Alphanumeric unencoded`() throws {
        let input = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let encoded = WHATWG_Form_URL_Encoded.PercentEncoding.encode(input, space: .plus)
        #expect(encoded == input)
    }

    @Test
    func `WHATWG Character Set: Allowed special characters unencoded`() throws {
        let input = "*-._"
        let encoded = WHATWG_Form_URL_Encoded.PercentEncoding.encode(input, space: .plus)
        #expect(encoded == input)
    }

    @Test
    func `WHATWG Character Set: Space encoding`() throws {
        let input = "hello world"

        let encodedAsPlus = WHATWG_Form_URL_Encoded.PercentEncoding.encode(input, space: .plus)
        #expect(encodedAsPlus == "hello+world")

        let encodedAsPercent = WHATWG_Form_URL_Encoded.PercentEncoding.encode(
            input,
            space: .percentEscaped
        )
        #expect(encodedAsPercent == "hello%20world")
    }

    @Test
    func `WHATWG Character Set: Special characters encoded`() throws {

        let testCases: [(String, String)] = [
            ("!", "%21"),
            ("@", "%40"),
            ("#", "%23"),
            ("$", "%24"),
            ("%", "%25"),
            ("^", "%5E"),
            ("&", "%26"),
            ("(", "%28"),
            (")", "%29"),
            ("+", "%2B"),
            ("=", "%3D"),
            ("[", "%5B"),
            ("]", "%5D"),
            ("{", "%7B"),
            ("}", "%7D"),
            ("|", "%7C"),
            ("\\", "%5C"),
            (":", "%3A"),
            (";", "%3B"),
            ("\"", "%22"),
            ("'", "%27"),
            ("<", "%3C"),
            (">", "%3E"),
            ("?", "%3F"),
            (",", "%2C"),
            ("/", "%2F"),
            ("~", "%7E"),
        ]

        for (input, expected) in testCases {
            let encoded = WHATWG_Form_URL_Encoded.PercentEncoding.encode(input, space: .plus)
            #expect(
                encoded == expected,
                "Character '\(input)' should encode to '\(expected)', got '\(encoded)'"
            )
        }
    }

    @Test
    func `Decode: Plus handling`() throws {
        let input = "hello+world"

        let decodedAsSpace = try WHATWG_Form_URL_Encoded.PercentEncoding.decode(
            input,
            space: .plus
        )
        #expect(decodedAsSpace == "hello world")

        let decodedAsPlus = try WHATWG_Form_URL_Encoded.PercentEncoding.decode(
            input,
            space: .percentEscaped
        )
        #expect(decodedAsPlus == "hello+world")
    }

    @Test
    func `Serialize: Empty array`() throws {
        let encoded = WHATWG_Form_URL_Encoded.serialize([])
        #expect(encoded.isEmpty)
    }

    @Test
    func `Serialize: Single pair`() throws {
        let encoded = WHATWG_Form_URL_Encoded.serialize([("key", "value")])
        #expect(encoded == "key=value")
    }
}

extension `README Verification`.`Edge Case` {
    @Test
    func `Parse: Empty values`() throws {
        let pairs = WHATWG_Form_URL_Encoded.parse("name=&email=test%40example.com")

        #expect(pairs.count == 2)
        #expect(pairs[0].0 == "name")
        #expect(pairs[0].1.isEmpty)
        #expect(pairs[1].0 == "email")
        #expect(pairs[1].1 == "test@example.com")
    }

    @Test
    func `Parse: Multiple equals signs`() throws {
        let pairs = WHATWG_Form_URL_Encoded.parse("equation=a%3Db%2Bc")

        #expect(pairs.count == 1)
        #expect(pairs[0].0 == "equation")
        #expect(pairs[0].1 == "a=b+c")
    }

    @Test
    func `Parse: Empty pairs filtered out`() throws {
        let pairs = WHATWG_Form_URL_Encoded.parse("name=value&&")

        #expect(pairs.count == 1)
        #expect(pairs[0].0 == "name")
        #expect(pairs[0].1 == "value")
    }

    @Test
    func `Decode: Invalid percent encoding throws`() throws {
        #expect(throws: WHATWG_Form_URL_Encoded.PercentEncoding.Error.self) {
            try WHATWG_Form_URL_Encoded.PercentEncoding.decode("%", space: .plus)
        }
        #expect(throws: WHATWG_Form_URL_Encoded.PercentEncoding.Error.self) {
            try WHATWG_Form_URL_Encoded.PercentEncoding.decode("%2", space: .plus)
        }
        #expect(throws: WHATWG_Form_URL_Encoded.PercentEncoding.Error.self) {
            try WHATWG_Form_URL_Encoded.PercentEncoding.decode("%GG", space: .plus)
        }
        #expect(throws: WHATWG_Form_URL_Encoded.PercentEncoding.Error.self) {
            try WHATWG_Form_URL_Encoded.PercentEncoding.decode("test%", space: .plus)
        }
    }

    @Test
    func `Parse: Empty string`() throws {
        let pairs = WHATWG_Form_URL_Encoded.parse("")
        #expect(pairs.isEmpty)
    }

    @Test
    func `UTF-8 Encoding: Multi-byte characters`() throws {
        let testCases = [
            ("🌍", "%F0%9F%8C%8D"),
            ("中文", "%E4%B8%AD%E6%96%87"),
            ("café", "caf%C3%A9"),
            ("Ångström", "%C3%85ngstr%C3%B6m"),
        ]

        for (input, expected) in testCases {
            let encoded = WHATWG_Form_URL_Encoded.PercentEncoding.encode(input, space: .plus)
            #expect(
                encoded == expected,
                "'\(input)' should encode to '\(expected)', got '\(encoded)'"
            )

            let decoded = try WHATWG_Form_URL_Encoded.PercentEncoding.decode(
                expected,
                space: .plus
            )
            #expect(
                decoded == input,
                "'\(expected)' should decode to '\(input)', got '\(decoded)'"
            )
        }
    }
}

extension `README Verification`.Integration {
    @Test
    func `Round trip: Serialize and parse`() throws {
        let original = [
            ("username", "john_doe"),
            ("email", "john@example.com"),
            ("message", "Hello, World! 🌍"),
        ]

        let encoded = WHATWG_Form_URL_Encoded.serialize(original)
        let decoded = WHATWG_Form_URL_Encoded.parse(encoded)

        #expect(decoded.count == original.count)
        for (index, pair) in original.enumerated() {
            #expect(decoded[index].0 == pair.0)
            #expect(decoded[index].1 == pair.1)
        }
    }

    @Test
    func `Round trip: Encode and decode`() throws {
        let strings = [
            "Hello World",
            "foo@bar.com",
            "test+value",
            "special!@#$%^&*()chars",
            "unicode🌍emoji",
            "hyphen-underscore_period.asterisk*",
        ]

        for original in strings {
            let encoded = WHATWG_Form_URL_Encoded.PercentEncoding.encode(
                original,
                space: .plus
            )
            let decoded = try WHATWG_Form_URL_Encoded.PercentEncoding.decode(
                encoded,
                space: .plus
            )
            #expect(decoded == original)
        }
    }
}
