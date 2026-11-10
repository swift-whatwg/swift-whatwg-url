# swift-whatwg-url

Use this package when you need to parse, resolve and serialize URLs following the WHATWG URL Standard's parser, or to encode and decode `application/x-www-form-urlencoded` text. Start from `WHATWG_URL.URL` for URLs and `WHATWG_URL.URL.Search.Params` for a query's name and value pairs. If you only need form encoding, use the `WHATWG Form URL Encoded` product and start from `WHATWG_Form_URL_Encoded`. If you need RFC 3986 URI syntax rather than browser URL parsing, use swift-rfc-3986.

## Laws

- Parsing trims leading and trailing spaces and tabs, and lowercases the scheme.
- A special scheme (`http`, `https`, `ws`, `wss`, `ftp`, `file`) must be followed by `//`. `http:example.com` is refused.
- With a base URL, empty input gives the base itself. A relative path replaces the base's last segment, `?query` keeps the base path, and `#fragment` keeps the base path and query.
- A port equal to the scheme's default is dropped while parsing, so `http://example.com:80/` has no port. Serialization also leaves out a default port set by hand. A port above 65535 is refused.
- Under a special scheme the host is an IPv4 address when it reads as one, in any WHATWG form (hex `0xC0`, octal `0300`, or fewer than four parts as in `192.168.257`), and otherwise must be a valid `Domain`. Under any other scheme the host is kept as an opaque string, unvalidated. An empty host, as in `file:///path`, is `WHATWG_URL.URL.Host.empty`.
- A bracketed IPv6 host has any zone ID after `%` dropped, and serializes in RFC 5952 form, as in `[2001:db8::1]`.
- Path segments are percent-decoded when parsed and stored decoded. `.` segments are removed, `..` removes the previous segment and does nothing at the root, and empty segments are dropped, so `http://example.com/` has an empty path.
- A second `@` in the authority is kept in the username as `%40`.
- `WHATWG_URL.URL.origin` is `null` for a URL without a special scheme.
- `WHATWG_URL.URL.Search.Params.set(_:_:)` removes every pair with that name and appends the new pair at the end.
- Form encoding writes UTF-8 and leaves only ASCII letters, digits and `*-._` unescaped. Escapes use uppercase hex. A space becomes `+` with `WHATWG_Form_URL_Encoded.SpaceEncoding.plus` and `%20` with `WHATWG_Form_URL_Encoded.SpaceEncoding.percentEscaped`, and decoding reads `+` as a space only under `plus`.
- `WHATWG_Form_URL_Encoded.PercentEncoding.decode(_:space:)` is strict: a `%` without two hex digits after it throws `invalidPercentEncoding`, and a `%` at the end throws `unexpectedEndOfInput`; those are its only errors. `WHATWG_Form_URL_Encoded.parse(_:)` follows the WHATWG rules instead: it skips empty pieces between `&`, gives an empty value to a name without `=`, and keeps a `%` without two hex digits after it as written, so `q=%zz` gives the value `%zz`.
- Decoded bytes that are not valid UTF-8 never throw: each invalid sequence becomes U+FFFD, as the WHATWG URL Standard's UTF-8 decode without BOM does.
