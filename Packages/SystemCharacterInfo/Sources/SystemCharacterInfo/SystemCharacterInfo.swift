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


import SQLite
import Foundation

private let path = "/System/Library/PrivateFrameworks/CoreChineseEngine.framework/Versions/A/Resources/CharacterAccessibilityData.sqlite"

public struct CharacterInfo {
    public let character: String?
    public let components: String?
    public let simplifiedExample: String?
    public let traditionalExample: String?
}

public enum SystemCharacterInfoError : Error, LocalizedError {
    case notFound

    public var errorDescription: String? {
        switch self {
        case .notFound:
            "Not Found"
        }
    }
}

public class SystemCharacterInfo {
    private var db: Connection

    public init() throws {
        self.db = try Connection(path)
    }

    public func read(string: String) throws -> CharacterInfo {
        let zentry = Table("ZENTRY")
        let zcharacter = Expression<String>("ZCHARACTER")
        let query = zentry.filter(zcharacter == string).limit(1)
        let result = try db.prepare(query)
        let rows = Array(result)
        guard let row = rows.first else {
            throw SystemCharacterInfoError.notFound
        }
        let ZSIMPLIFIEDEXEMPLAR = Expression<String?>("ZSIMPLIFIEDEXEMPLAR")
        let ZTRADITIONALEXEMPLAR = Expression<String?>("ZTRADITIONALEXEMPLAR")
        let ZCOMPONENTS = Expression<String?>("ZCOMPONENTS")
        let ZCHARACTER = Expression<String?>("ZCHARACTER")

        return CharacterInfo(
            character: try? row.get(ZCHARACTER),
            components: try? row.get(ZCOMPONENTS),
            simplifiedExample: try? row.get(ZSIMPLIFIEDEXEMPLAR),
            traditionalExample: try? row.get(ZTRADITIONALEXEMPLAR)
        )
    }
}
