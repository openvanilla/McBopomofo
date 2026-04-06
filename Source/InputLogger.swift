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

class InputLogger {

    static let shared = InputLogger(
        logDirectory: FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/McBopomofo")
    )

    private let queue = DispatchQueue(label: "org.openvanilla.McBopomofo.inputLogger")
    private var fileHandle: FileHandle?
    private var currentMonth: String = ""
    private let logDirectory: URL

    // UTC+8 (Taiwan) for consistent log timestamps regardless of system timezone
    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        f.timeZone = TimeZone(secondsFromGMT: 8 * 3600)
        return f
    }()

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        f.timeZone = TimeZone(secondsFromGMT: 8 * 3600)
        return f
    }()

    init(logDirectory: URL) {
        self.logDirectory = logDirectory
    }

    func log(text: String, reading: String) {
        let timestamp = Self.timestampFormatter.string(from: Date())
        let month = Self.monthFormatter.string(from: Date())
        queue.async { [weak self] in
            self?._log(timestamp: timestamp, month: month, text: text, reading: reading)
        }
    }

    func flush() {
        queue.sync {
            fileHandle?.synchronizeFile()
        }
    }

    private func _log(timestamp: String, month: String, text: String, reading: String) {
        if month != currentMonth {
            fileHandle?.closeFile()
            fileHandle = nil
            currentMonth = month
        }

        if fileHandle == nil {
            _openFile(month: month)
        }

        let sanitizedText = text.replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
        let sanitizedReading = reading.replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
        let line = "\(timestamp)\t\(sanitizedReading)\t\(sanitizedText)\n"

        if let data = line.data(using: .utf8) {
            fileHandle?.seekToEndOfFile()
            fileHandle?.write(data)
        }
    }

    private func _openFile(month: String) {
        try? FileManager.default.createDirectory(
            at: logDirectory, withIntermediateDirectories: true)
        let filePath = logDirectory
            .appendingPathComponent("input-log-\(month).tsv")
        if !FileManager.default.fileExists(atPath: filePath.path) {
            FileManager.default.createFile(atPath: filePath.path, contents: nil)
        }
        fileHandle = try? FileHandle(forWritingTo: filePath)
        fileHandle?.seekToEndOfFile()
    }
}
