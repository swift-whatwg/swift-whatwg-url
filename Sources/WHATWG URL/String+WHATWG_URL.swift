//
//  String+WHATWG_URL.swift
//  swift-whatwg-url
//
//  WHATWG URL Standard extensions for String
//  Provides URL serialization per WHATWG URL Standard Section 4.5

public import ASCII_Serializer_Primitives

// MARK: - Namespace Wrapper

// TODO: syntax should be instance.whatwg.url.method etc. NOT whatwgURL
extension StringProtocol {
    /// Access to WHATWG URL operations
    public static var whatwgURL: WHATWG_URL.StringProtocol<Self>.Type {
        WHATWG_URL.StringProtocol<Self>.self
    }

    /// Access to WHATWG URL operations for this string
    public var whatwgURL: WHATWG_URL.StringProtocol<Self> {
        WHATWG_URL.StringProtocol(self)
    }
}

// MARK: - Serialization: WHATWG_URL → String

extension String {
    /// Creates a string by serializing a WHATWG URL
    ///
    /// Uses `Binary.ASCII.Serializable` pattern.
    ///
    /// Per WHATWG URL Standard Section 4.5, URL serialization produces an ASCII string
    /// where parsing the result yields an equivalent URL.
    ///
    /// - Parameter whatwgURL: The URL to serialize
    /// - Returns: Serialized URL string (href)
    @inlinable
    public init(whatwgURL url: WHATWG_URL.URL) {
        self = String(ascii: url)
    }

    /// Creates a string from the URL's origin
    ///
    /// - Parameter origin: The URL to extract origin from
    /// - Returns: Origin string or "null" for opaque origins
    @inlinable
    public init(whatwgOrigin url: WHATWG_URL.URL) {
        self = url.origin
    }
}

// MARK: - URL Serialization

extension WHATWG_URL.StringProtocol {
    /// Serializes a URL to its string representation
    ///
    /// Uses `Binary.ASCII.Serializable` pattern.
    ///
    /// - Parameter url: The URL to serialize
    /// - Returns: Serialized URL string
    @inlinable
    public static func serialize(_ url: WHATWG_URL.URL) -> S {
        S(String(ascii: url))!
    }

    /// Serializes just the origin portion of a URL
    ///
    /// - Parameter url: The URL to extract origin from
    /// - Returns: Origin string
    @inlinable
    public static func serializeOrigin(_ url: WHATWG_URL.URL) -> S {
        S(url.origin)!
    }
}

extension String {
    /// Creates a string representation of a WHATWG URL Host
    ///
    /// Uses `Binary.ASCII.Serializable` pattern.
    ///
    /// - Parameter host: The WHATWG URL host to serialize
    @inlinable
    public init(_ host: WHATWG_URL.URL.Host) {
        self = String(ascii: host)
    }

    /// Creates a string representation of a WHATWG URL Path
    ///
    /// Uses `Binary.ASCII.Serializable` pattern.
    ///
    /// - Parameter path: The WHATWG URL path to serialize
    @inlinable
    public init(_ path: WHATWG_URL.URL.Path) {
        self = String(ascii: path)
    }

    /// Creates a string representation of WHATWG URL Search Parameters
    ///
    /// Delegates to the search parameters' string representation.
    ///
    /// - Parameter searchParams: The search parameters to serialize
    @inlinable
    public init(_ searchParams: WHATWG_URL.URL.Search.Params) {
        self = searchParams.toString()
    }
}
