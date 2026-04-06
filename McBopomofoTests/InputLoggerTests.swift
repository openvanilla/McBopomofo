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
import Testing

@testable import McBopomofo

@Suite("InputLogger Tests", .serialized)
final class InputLoggerTests {

    let testDir: URL

    init() throws {
        testDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("McBopomofoLogTest-\(UUID().uuidString)")
    }

    deinit {
        try? FileManager.default.removeItem(at: testDir)
    }

    @Test func logWritesTSVLine() throws {
        let logger = InputLogger(logDirectory: testDir)
        logger.log(text: "today", reading: "ㄐㄧㄣ-ㄊㄧㄢ")
        logger.flush()

        let files = try FileManager.default.contentsOfDirectory(
            at: testDir, includingPropertiesForKeys: nil)
        #expect(files.count == 1)
        #expect(files[0].lastPathComponent.hasPrefix("input-log-"))
        #expect(files[0].pathExtension == "tsv")

        let content = try String(contentsOf: files[0], encoding: .utf8)
        let lines = content.split(separator: "\n")
        #expect(lines.count == 1)

        let columns = lines[0].split(separator: "\t", maxSplits: 2)
        #expect(columns.count == 3)
        #expect(columns[1] == "ㄐㄧㄣ-ㄊㄧㄢ")
        #expect(columns[2] == "today")
    }

    @Test func logWithEmptyReading() throws {
        let logger = InputLogger(logDirectory: testDir)
        logger.log(text: "Hello", reading: "")
        logger.flush()

        let files = try FileManager.default.contentsOfDirectory(
            at: testDir, includingPropertiesForKeys: nil)
        let content = try String(contentsOf: files[0], encoding: .utf8)
        let columns = content.split(separator: "\n")[0]
            .split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false)
        #expect(columns.count == 3)
        #expect(columns[1] == "")
        #expect(columns[2] == "Hello")
    }

    @Test func logMultipleEntriesAppend() throws {
        let logger = InputLogger(logDirectory: testDir)
        logger.log(text: "a", reading: "ㄟ")
        logger.log(text: "b", reading: "ㄅㄧˋ")
        logger.flush()

        let files = try FileManager.default.contentsOfDirectory(
            at: testDir, includingPropertiesForKeys: nil)
        let content = try String(contentsOf: files[0], encoding: .utf8)
        let lines = content.split(separator: "\n")
        #expect(lines.count == 2)
    }
}
