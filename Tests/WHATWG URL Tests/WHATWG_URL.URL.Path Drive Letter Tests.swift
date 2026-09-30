import Testing

@testable import WHATWG_URL

@Suite
struct `Path drive letters` {
    @Test
    func `a lone ASCII drive letter survives shortening a file path`() {
        var path = WHATWG_URL.URL.Path.list(["C:"])
        let shortened = path.shorten(scheme: .file)
        #expect(!shortened)
        #expect(path == .list(["C:"]))
    }

    @Test(arguments: ["é:", "Ω:", "1:"])
    func `a lone non-ASCII-alpha segment is not a drive letter and is removed`(_ segment: String) {
        var path = WHATWG_URL.URL.Path.list([segment])
        let shortened = path.shorten(scheme: .file)
        #expect(shortened)
        #expect(path == .list([]))
    }
}
