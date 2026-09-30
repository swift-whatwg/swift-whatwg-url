import Testing

@testable import WHATWG_URL

@Suite
struct `Percent decoding of signed hex` {
    @Test(arguments: ["%+F", "a%-0b", "%+1%41"])
    func `a percent sign followed by a sign character stays literal`(_ input: String) {
        #expect(WHATWG_URL.PercentEncoding.decode(input) == input.replacingOccurrences("%41", "A"))
    }
}

extension String {
    fileprivate func replacingOccurrences(_ target: String, _ replacement: String) -> String {
        split(separator: target, omittingEmptySubsequences: false).joined(separator: replacement)
    }
}
