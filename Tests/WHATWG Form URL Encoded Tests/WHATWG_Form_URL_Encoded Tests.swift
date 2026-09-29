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
