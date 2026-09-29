import Domain_Standard
import RFC_791
import Testing

@testable import WHATWG_URL

extension WHATWG_URL.URL {
    @Suite("WHATWG URL Components")
    struct Test {

        @Test
        func `URL structure initialization`() throws {
            let url = WHATWG_URL.URL(
                scheme: .https,
                username: "user",
                password: "pass",
                host: .domain(try Domain("example.com")),
                port: 8080,
                path: .list(["path", "to", "resource"]),
                query: "key=value",
                fragment: "section"
            )

            #expect(url.scheme == .https)
            #expect(url.username == "user")
            #expect(url.password == "pass")
            #expect(url.host == .domain(try Domain("example.com")))
            #expect(url.port == 8080)
            #expect(url.path == .list(["path", "to", "resource"]))
            #expect(url.query == "key=value")
            #expect(url.fragment == "section")
        }

        @Test
        func `URL serialization with all components`() throws {
            let url = WHATWG_URL.URL(
                scheme: .https,
                username: "user",
                password: "pass",
                host: .domain(try Domain("example.com")),
                port: 8080,
                path: .list(["path", "to", "resource"]),
                query: "key=value",
                fragment: "section"
            )

            let href = url.href
            #expect(
                href.value
                    == "https://user:pass@example.com:8080/path/to/resource?key=value#section"
            )
        }

        @Test
        func `URL serialization without credentials`() throws {
            let url = WHATWG_URL.URL(
                scheme: .https,
                host: .domain(try Domain("example.com")),
                path: .list(["path"])
            )

            let href = url.href
            #expect(href.value == "https://example.com/path")
        }

        @Test
        func `URL serialization with default port omitted`() throws {

            let url = WHATWG_URL.URL(
                scheme: .https,
                host: .domain(try Domain("example.com")),
                port: 443,
                path: .list(["path"])
            )

            let href = url.href
            #expect(href.value == "https://example.com/path")
        }

        @Test
        func `URL serialization with non-default port`() throws {
            let url = WHATWG_URL.URL(
                scheme: .https,
                host: .domain(try Domain("example.com")),
                port: 8443,
                path: .list(["path"])
            )

            let href = url.href
            #expect(href.value == "https://example.com:8443/path")
        }

        @Test
        func `WHATWG_URL.URL.SearchParams parsing`() throws {
            let params = WHATWG_URL.URL.Search.Params(
                "name=John+Doe&email=john%40example.com&age=30"
            )

            #expect(params.get("name") == "John Doe")
            #expect(params.get("email") == "john@example.com")
            #expect(params.get("age") == "30")
            #expect(params.get("missing") == nil)
        }

        @Test
        func `WHATWG_URL.URL.SearchParams building`() throws {
            var params = WHATWG_URL.URL.Search.Params()
            params.append("name", "John Doe")
            params.append("email", "john@example.com")

            let query = params.description
            #expect(query == "name=John+Doe&email=john%40example.com")
        }

        @Test
        func `WHATWG_URL.URL.SearchParams set and delete`() throws {
            var params = WHATWG_URL.URL.Search.Params()
            params.append("key", "value1")
            params.append("key", "value2")

            #expect(params.getAll("key") == ["value1", "value2"])

            params.set("key", "newvalue")
            #expect(params.get("key") == "newvalue")
            #expect(params.getAll("key") == ["newvalue"])

            params.delete("key")
            #expect(params.get("key") == nil)
        }

        @Test
        func `URLHost IPv4 serialization`() throws {
            let address = try RFC_791.IPv4.Address("192.168.1.1")
            let host = WHATWG_URL.URL.Host.ipv4(address)
            #expect(host.description == "192.168.1.1")
        }

        @Test
        func `URLHost domain serialization`() throws {
            let host = WHATWG_URL.URL.Host.domain(try Domain("example.com"))
            #expect(host.description == "example.com")
        }

        @Test
        func `URLPath list serialization`() throws {
            let path = WHATWG_URL.URL.Path.list(["path", "to", "resource"])
            #expect(path.description == "/path/to/resource")
        }

        @Test
        func `URLPath empty list serialization`() throws {
            let path = WHATWG_URL.URL.Path.emptyList
            #expect(path.description.isEmpty)
        }

        @Test
        func `URLPath opaque serialization`() throws {
            let path = WHATWG_URL.URL.Path.opaque("opaque-data")
            #expect(path.description == "opaque-data")
        }

        @Test
        func `URLScheme special schemes`() throws {
            #expect(WHATWG_URL.URL.Scheme.isSpecial(.http))
            #expect(WHATWG_URL.URL.Scheme.isSpecial(.https))
            #expect(WHATWG_URL.URL.Scheme.isSpecial(.ftp))
            #expect(WHATWG_URL.URL.Scheme.isSpecial(.file))
            #expect(WHATWG_URL.URL.Scheme.isSpecial(.ws))
            #expect(WHATWG_URL.URL.Scheme.isSpecial(.wss))
            #expect(!WHATWG_URL.URL.Scheme.isSpecial(try .init("mailto")))
            #expect(!WHATWG_URL.URL.Scheme.isSpecial(try .init("data")))
        }

        @Test
        func `URLScheme default ports`() throws {
            #expect(WHATWG_URL.URL.Scheme.defaultPort(for: .http) == 80)
            #expect(WHATWG_URL.URL.Scheme.defaultPort(for: .https) == 443)
            #expect(WHATWG_URL.URL.Scheme.defaultPort(for: .ftp) == 21)
            #expect(WHATWG_URL.URL.Scheme.defaultPort(for: .ws) == 80)
            #expect(WHATWG_URL.URL.Scheme.defaultPort(for: .wss) == 443)
            #expect(WHATWG_URL.URL.Scheme.defaultPort(for: .file) == nil)
        }

        @Test
        func `URL origin for special schemes`() throws {
            let url = WHATWG_URL.URL(
                scheme: .https,
                host: .domain(try Domain("example.com")),
                port: 443,
                path: .list(["path"])
            )

            #expect(url.origin == "https://example.com")
        }

        @Test
        func `URL searchParams getter and setter`() throws {
            var url = WHATWG_URL.URL(
                scheme: .https,
                host: .domain(try Domain("example.com")),
                path: .list(["path"]),
                query: "name=John&age=30"
            )

            let params = url.searchParams
            #expect(params.get("name") == "John")
            #expect(params.get("age") == "30")

            var newParams = WHATWG_URL.URL.Search.Params()
            newParams.append("email", "john@example.com")
            url.searchParams = newParams

            #expect(url.query == "email=john%40example.com")
        }
    }
}
