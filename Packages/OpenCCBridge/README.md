# OpenCCBridge

Copyright (c) 2022 and onwards The McBopomofo Authors.

OpenCCBridge exposes SwiftyOpenCC conversion utilities to Objective-C and
Objective-C++ code by wrapping them in an `NSObject` subclass. The package
provides a tiny bridging layer so the main McBopomofo app can convert between
Traditional and Simplified Chinese without reimplementing OpenCC bindings.

## Requirements

- macOS 10.15 or later
- Swift 5.9 or later
- SwiftyOpenCC 2.0.0-beta (resolves automatically via Swift Package Manager)
- Foundation and OpenCC frameworks linked in the host target

## API Overview

- `OpenCCBridge.shared` lazily configures paired converters and shares them
  across the process.
- `convertToSimplified(_:)` converts Traditional Chinese text to Simplified
  Chinese.
- `convertToTraditional(_:)` converts Simplified Chinese text to Traditional
  Chinese.

## Usage Examples

### Swift

```swift
import OpenCCBridge

let simplified = OpenCCBridge.shared.convertToSimplified("\u{9EA5}")
let traditional = OpenCCBridge.shared.convertToTraditional("\u{9EA6}")
```

### Objective-C++

```objective-c++
#import <OpenCCBridge/OpenCCBridge-Swift.h>

NSString *simplified = [[OpenCCBridge sharedInstance] convertToSimplified:@"\u9EA5"];
NSString *traditional = [[OpenCCBridge sharedInstance] convertToTraditional:@"\u9EA6"];
```

## Integration Notes

- Always access the shared singleton; the underlying `ChineseConverter` objects
  are expensive to create and maintain custom conversion caches.
- The conversion methods return optionals; when bridging from Objective-C, check
  for `nil` to catch failures caused by resource loading issues.
- Callers are responsible for running on the correct thread; conversions are
  thread-safe but the bridge does not provide additional locking.

## License

This package is released under the MIT license. See the header comments in the
source files for the full text.
