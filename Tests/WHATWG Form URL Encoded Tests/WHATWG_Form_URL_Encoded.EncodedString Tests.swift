import Byte
import Byte
import Testing

@testable import WHATWG_Form_URL_Encoded

@Suite
struct `WHATWG_Form_URL_Encoded.EncodedString Tests` {

    @Test
    func `an encoded string renders the form-urlencoded text`() throws {
        let encoded = WHATWG_Form_URL_Encoded.EncodedString(encoding: "Hello World!")
        #expect(encoded.description == "Hello+World%21")
        #expect(try encoded.decoded() == "Hello World!")
    }

    @Test
    func `an encoded string reads back from its own bytes`() throws {
        let encoded = WHATWG_Form_URL_Encoded.EncodedString(encoding: "Hello World!")
        let bytes = [Byte](utf8: encoded.rawValue)
        #expect(WHATWG_Form_URL_Encoded.EncodedString(ascii: bytes) == encoded)
    }
}
