# swift-whatwg-url

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

WHATWG URL Living Standard implementation in Swift.

## Overview

This package implements the [WHATWG URL Living Standard](https://url.spec.whatwg.org/), providing:

- **WHATWG URL**: URL parsing, serialization, and component access through the standard's state-machine parser — `try WHATWG_URL.URL(_:)` yields a `WHATWG_URL.URL` with `scheme`, `username`, `password`, `host` (domain, IPv4, IPv6, opaque, or empty, including IDNA), `port`, `path`, `query`, `fragment`, and an `href` serialization.
- **WHATWG Form URL Encoded**: Section 5 - `application/x-www-form-urlencoded` encoding and decoding

The WHATWG URL Standard defines the precise character set and encoding rules for URL form encoding, which differs from Foundation's URL encoding in key ways:

- **Space encoding**: WHATWG uses `+`, Foundation uses `%20`
- **Character set**: WHATWG only leaves alphanumeric + `*-._` unencoded
- **Specification compliance**: Exact implementation of the WHATWG algorithm

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-whatwg/swift-whatwg-url", branch: "main")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        // For URL parsing, serialization, and component access
        .product(name: "WHATWG URL", package: "swift-whatwg-url"),

        // Or just for form URL encoding
        .product(name: "WHATWG Form URL Encoded", package: "swift-whatwg-url")
    ]
)
```

## Usage

### WHATWG URL

```swift
import WHATWG_URL

let url = try WHATWG_URL.URL("https://example.com:8080/path?query=value#fragment")

url.scheme      // "https"
url.host        // Optional(.domain("example.com"))
url.port        // Optional(8080)
url.path        // .list(["path"])
url.query       // Optional("query=value")
url.fragment    // Optional("fragment")

let urlString = url.href.value  // "https://example.com:8080/path?query=value#fragment"
```

### WHATWG Form URL Encoded

#### Serialize to application/x-www-form-urlencoded

```swift
import WHATWG_Form_URL_Encoded

let encoded = WHATWG_Form_URL_Encoded.serialize([
    ("name", "John Doe"),
    ("email", "john@example.com")
])
// Result: "name=John+Doe&email=john%40example.com"
```

#### Parse application/x-www-form-urlencoded

```swift
let pairs = WHATWG_Form_URL_Encoded.parse("name=John+Doe&email=john%40example.com")
// Result: [("name", "John Doe"), ("email", "john@example.com")]
```

#### Percent Encoding

```swift
let encoded = WHATWG_Form_URL_Encoded.PercentEncoding.encode("Hello World!", space: .plus)
// Result: "Hello+World%21"
```

#### Percent Decoding

```swift
let decoded = try WHATWG_Form_URL_Encoded.PercentEncoding.decode("Hello+World%21", space: .plus)
// Result: "Hello World!"
```

## WHATWG Character Set

According to the WHATWG URL Standard, only the following characters are left unencoded:

- ASCII alphanumeric (`a-z`, `A-Z`, `0-9`)
- Asterisk (`*`)
- Hyphen (`-`)
- Period (`.`)
- Underscore (`_`)

All other characters are percent-encoded. Space (0x20) is encoded as `+` when `space` is `.plus`.

## Difference from Foundation

Foundation's `URLComponents` and related APIs use a different encoding scheme:

```swift
// WHATWG (this package)
"Hello World!" → "Hello+World%21"

// Foundation
"Hello World!" → "Hello%20World!"  // Different space encoding
```

Additionally, Foundation's URL encoding is more permissive with special characters, while WHATWG strictly limits unencoded characters to the set above.

## Reference

- [WHATWG URL Living Standard](https://url.spec.whatwg.org/)
- [Section 5: application/x-www-form-urlencoded](https://url.spec.whatwg.org/#application/x-www-form-urlencoded)

## Requirements

- Swift 6.4+
- macOS 27+, iOS 27+, tvOS 27+, watchOS 27+

## License

Apache 2.0
