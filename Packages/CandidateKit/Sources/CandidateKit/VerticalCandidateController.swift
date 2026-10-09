// Copyright (c) 2026 and onwards The McBopomofo Authors.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

import AppKit

@MainActor
@objc(CKVerticalCandidateController)
public final class VerticalCandidateController: CandidateController {
    @objc public var expandable: Bool {
        get { configuration.allowsExpansion }
        set {
            var updatedConfiguration = configuration
            updatedConfiguration.allowsExpansion = newValue
            try? apply(configuration: updatedConfiguration)
        }
    }

    @objc public convenience init() {
        self.init(expandable: true)
    }

    @objc public init(expandable: Bool) {
        var configuration = CandidateConfiguration.default
        configuration.orientation = .vertical
        configuration.allowsExpansion = expandable
        super.init(configuration: configuration)
    }

    public required init?(coder: NSCoder) {
        nil
    }
}
