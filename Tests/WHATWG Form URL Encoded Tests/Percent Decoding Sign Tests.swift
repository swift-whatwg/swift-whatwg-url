import Testing

@testable import WHATWG_Form_URL_Encoded

@Suite
struct `Form percent decoding of signed hex` {
    @Test(arguments: ["%+F", "a%-0b", "%-F"])
    func `a percent sign followed by a sign character is invalid`(_ input: String) {
        #expect(throws: WHATWG_Form_URL_Encoded.PercentEncoding.Error.self) {
            try WHATWG_Form_URL_Encoded.PercentEncoding.decode(input)
        }
    }

    @Test
    func `lowercase and uppercase hex digits still decode`() throws {
        #expect(try WHATWG_Form_URL_Encoded.PercentEncoding.decode("%4a%4A") == "JJ")
    }
}
