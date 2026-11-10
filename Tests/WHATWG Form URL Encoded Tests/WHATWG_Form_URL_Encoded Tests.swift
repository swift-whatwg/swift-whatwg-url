import Testing

@testable import WHATWG_Form_URL_Encoded

@Suite
struct `WHATWG_Form_URL_Encoded Tests` {

    @Test
    func `serialization percent-encodes names and values with plus for space`() {
        #expect(
            WHATWG_Form_URL_Encoded.serialize([
                ("name", "John Doe"),
                ("email", "john@example.com"),
                ("message", "Hello World!"),
            ]) == "name=John+Doe&email=john%40example.com&message=Hello+World%21"
        )
    }
}

extension `WHATWG_Form_URL_Encoded Tests` {

    @Test
    func `a pair with a bad percent escape is kept with the escape as written`() {
        let pairs = WHATWG_Form_URL_Encoded.parse("q=%zz&a%=b%2&c=%41")
        #expect(pairs.map(\.0) == ["q", "a%", "c"])
        #expect(pairs.map(\.1) == ["%zz", "b%2", "A"])
    }

    @Test
    func `a pair without an equals sign is kept with an empty value`() {
        let pairs = WHATWG_Form_URL_Encoded.parse("x&y=1")
        #expect(pairs.map(\.0) == ["x", "y"])
        #expect(pairs.map(\.1) == ["", "1"])
    }
}

extension `WHATWG_Form_URL_Encoded Tests` {

    @Test
    func `a percent-encoded byte that is not UTF-8 decodes to the replacement character`() throws {
        #expect(try WHATWG_Form_URL_Encoded.PercentEncoding.decode("a%FFb") == "a\u{FFFD}b")
        #expect(WHATWG_Form_URL_Encoded.parse("q=%C3").map(\.1) == ["\u{FFFD}"])
    }
}
