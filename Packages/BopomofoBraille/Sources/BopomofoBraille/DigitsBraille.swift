// Copyright (c) 2022 and onwards The McBopomofo Authors.
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

import Foundation

enum Digit: String, CaseIterable {

    var digit: String {
        return rawValue
    }

    var braille: String {
        switch self {
        case .zero:
            "⠴"
        case .one:
            "⠂"
        case .two:
            "⠆"
        case .three:
            "⠒"
        case .four:
            "⠲"
        case .five:
            "⠢"
        case .six:
            "⠖"
        case .seven:
            "⠶"
        case .eight:
            "⠦"
        case .nine:
            "⠔"
        }
    }

    case zero = "0"
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
}

enum DigitRelated: String, CaseIterable {
    var braille: String {
        switch self {
        case .point:
            "⠨"
        case .percent:
            "⠈⠴"
        case .celsius:
            "⠘⠨⠡ ⠰⠠⠉"
        }

    }

    case point = "."
    case percent = "%"
    case celsius = "°C"
}
