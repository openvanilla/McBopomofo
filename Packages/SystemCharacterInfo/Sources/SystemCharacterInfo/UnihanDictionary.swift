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


import SQLite
import Foundation

private let path = "/System/Library/Input Methods/CharacterPalette.app/Contents/Resources/CharacterDB.sqlite3"

public struct UnihanEntry {
    public var name: String
    public var japanese: String
    /// 日文訓讀
    public var japaneseKun: String
    /// 日文音讀
    public var japaneseOn: String
    public var korean: String
    public var pinyinPrc: String
    public var pinyinRoc: String
    public var pinyinPrimary: String
    public var canjie: String
    public var canjieKeys: String
    public var components: String
    public var phonetic: String
    /// 五筆形
    public var wubiXing: String
    /// 五筆劃
    public var wubiHua: String
}

public class UnihanDictionary {
    public static let shared: UnihanDictionary? = try? UnihanDictionary()

    class UnihanEntryParser {
        static func parse(from string: String) -> UnihanEntry {
            let components = string.split(separator: "|", omittingEmptySubsequences: false)
            func get(_ index: Int) -> String {
                return index < components.count ? String(components[index]) : ""
            }
            return UnihanEntry(
                name: get(0),
                japanese: get(1),
                japaneseKun: get(12),
                japaneseOn: get(13),
                korean: get(2),
                pinyinPrc: get(3),
                pinyinRoc: get(10),
                pinyinPrimary: get(14),
                canjie: get(8),
                canjieKeys: get(15),
                components: get(7),
                phonetic: get(11),
                wubiXing: get(4),
                wubiHua: get(5)
            )
        }
    }

    private var db: Connection

    public init() throws {
        self.db = try Connection(path)
    }

    public func read(string: String) throws -> UnihanEntry {
        let table = Table("unihan_dict")
        let uchr = Expression<String>("uchr")
        let query = table.filter(uchr == string).limit(1)
        let result = try db.prepare(query)
        let rows = Array(result)
        guard let row = rows.first else {
            throw SystemCharacterInfoError.notFound
        }
        let info = SQLite.Expression<String?>("info")
        let infoString = try? row.get(info)
        guard let infoString else {
            throw SystemCharacterInfoError.notFound
        }
        let entry = UnihanEntryParser.parse(from: infoString)
        return entry
    }
}
