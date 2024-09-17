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

/// Represents the letters.
public enum Letter: String, CaseIterable {

    static let bpmfBrailleMap: [Letter: (String, String)] = [
        .a: ("⠁", "1"),
        .b: ("⠃", "12"),
        .c: ("⠉", "14"),
        .d: ("⠙", "145"),
        .e: ("⠑", "15"),
        .f: ("⠋", "124"),
        .g: ("⠛", "1245"),
        .h: ("⠓", "125"),
        .i: ("⠊", "24"),
        .j: ("⠚", "245"),
        .k: ("⠅", "13"),
        .l: ("⠇", "123"),
        .m: ("⠍", "134"),
        .n: ("⠝", "1345"),
        .o: ("⠕", "135"),
        .p: ("⠏", "1234"),
        .q: ("⠟", "12345"),
        .r: ("⠗", "1235"),
        .s: ("⠎", "234"),
        .t: ("⠞", "2345"),
        .u: ("⠥", "136"),
        .v: ("⠧", "1236"),
        .w: ("⠺", "2456"),
        .x: ("⠭", "1346"),
        .y: ("⠽", "13456"),
        .z: ("⠵", "1356"),
    ]

    init?(braille: String) {
        let aCase = Letter.allCases.first { aCase in
            aCase.braille == braille
        }
        if let aCase {
            self = aCase
        } else {
            return nil
        }
    }

    var bopomofo: String {
        return rawValue
    }

    var braille: String {
        Letter.bpmfBrailleMap[self]!.0
    }

    var brailleCode: String {
        Letter.bpmfBrailleMap[self]!.1
    }

    case a = "a"
    case b = "b"
    case c = "c"
    case d = "d"
    case e = "e"
    case f = "f"
    case g = "g"
    case h = "h"
    case i = "i"
    case j = "j"
    case k = "k"
    case l = "l"
    case m = "m"
    case n = "n"
    case o = "o"
    case p = "p"
    case q = "q"
    case r = "r"
    case s = "s"
    case t = "t"
    case u = "u"
    case v = "v"
    case w = "w"
    case x = "x"
    case y = "y"
    case z = "z"
}
