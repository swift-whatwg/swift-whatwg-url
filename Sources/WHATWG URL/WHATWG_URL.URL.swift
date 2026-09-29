import WHATWG_Form_URL_Encoded

extension WHATWG_URL {
    public struct URL: Hashable, Sendable {

        public var scheme: Scheme

        public var username: String

        public var password: String

        public var host: Host?

        public var port: UInt16?

        public var path: Path

        public var query: String?

        public var fragment: String?

        public init(
            scheme: Scheme,
            username: String = "",
            password: String = "",
            host: Host? = nil,
            port: UInt16? = nil,
            path: Path = .emptyList,
            query: String? = nil,
            fragment: String? = nil
        ) {
            self.scheme = scheme
            self.username = username
            self.password = password
            self.host = host
            self.port = port
            self.path = path
            self.query = query
            self.fragment = fragment
        }
    }
}

extension WHATWG_URL.URL {

    public var isSpecial: Bool {
        Scheme.isSpecial(scheme)
    }

    public var hasOpaquePath: Bool {
        if case .opaque = path {
            return true
        }
        return false
    }

    public var includesCredentials: Bool {
        return !username.isEmpty || !password.isEmpty
    }

    public var cannotHaveUsernamePasswordPort: Bool {

        if host == nil || host == .empty {
            return true
        }
        return scheme.value == "file"
    }

    public var searchParams: Search.Params {
        get {
            if let query {
                return Search.Params(query)
            }
            return Search.Params()
        }
        set {
            let serialized = newValue.description
            query = serialized.isEmpty ? nil : serialized
        }
    }
}

extension WHATWG_URL.URL {

    public var href: Href {
        Href(self)
    }

    public var origin: String {

        guard isSpecial else {
            return "null"
        }

        var output = scheme.value + "://"

        if let host {
            output += host.description
        }

        if let port, Scheme.defaultPort(for: scheme) != port {
            output += ":" + String(port)
        }

        return output
    }
}
