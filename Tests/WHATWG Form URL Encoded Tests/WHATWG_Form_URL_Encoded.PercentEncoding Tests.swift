import Testing

@testable import WHATWG_Form_URL_Encoded

@Suite
struct `WHATWG_Form_URL_Encoded.PercentEncoding Tests` {

    @Test
    func `an empty string encodes to an empty string`() {
        #expect(WHATWG_Form_URL_Encoded.PercentEncoding.encode("", space: .plus).isEmpty)
    }

    @Test
    func `every space encodes as a plus`() {
        #expect(WHATWG_Form_URL_Encoded.PercentEncoding.encode("   ", space: .plus) == "+++")
        #expect(
            WHATWG_Form_URL_Encoded.PercentEncoding.encode("first second third", space: .plus)
                == "first+second+third"
        )
    }

    @Test
    func `a literal plus is percent-encoded`() {
        #expect(WHATWG_Form_URL_Encoded.PercentEncoding.encode("a+b", space: .plus) == "a%2Bb")
    }

    @Test
    func `a plus decodes as a space`() throws {
        #expect(
            try WHATWG_Form_URL_Encoded.PercentEncoding.decode("John+Doe", space: .plus)
                == "John Doe"
        )
    }

    @Test
    func `tilde, parentheses and exclamation mark inside text are percent-encoded`() {
        #expect(
            WHATWG_Form_URL_Encoded.PercentEncoding.encode("test~value", space: .plus)
                == "test%7Evalue"
        )
        #expect(
            WHATWG_Form_URL_Encoded.PercentEncoding.encode("func(arg)", space: .plus)
                == "func%28arg%29"
        )
        #expect(
            WHATWG_Form_URL_Encoded.PercentEncoding.encode("Hello World!", space: .plus)
                == "Hello+World%21"
        )
    }

    @Test
    func `only alphanumerics and asterisk, hyphen, period, underscore stay unencoded`() {
        #expect(
            WHATWG_Form_URL_Encoded.PercentEncoding.encode("abc123*-._", space: .plus)
                == "abc123*-._"
        )
        #expect(
            WHATWG_Form_URL_Encoded.PercentEncoding.encode(
                "!@#$^&()+={}[]|\\:;\"'<>?,/~",
                space: .plus
            )
                == "%21%40%23%24%5E%26%28%29%2B%3D%7B%7D%5B%5D%7C%5C%3A%3B%22%27%3C%3E%3F%2C%2F%7E"
        )
    }
}
