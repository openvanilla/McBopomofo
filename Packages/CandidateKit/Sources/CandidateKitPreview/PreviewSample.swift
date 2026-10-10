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
import CandidateKit

enum PreviewSample: String, CaseIterable {
    case candidates, associated, plainAssociated = "plain-associated", numbers, icu, details
    case shortList = "short-list", longList = "long-list"

    var title: String {
        switch self {
        case .candidates: "Candidates"
        case .associated: "Automatic Associated Phrases"
        case .plainAssociated: "Plain Bopomofo Associated Phrases"
        case .numbers: "Number Formats"
        case .icu: "ICU Transforms"
        case .details: "Candidate Details"
        case .shortList: "Short List"
        case .longList: "Long List"
        }
    }

    var usesShiftedKeys: Bool {
        self == .plainAssociated || self == .numbers || self == .icu
    }

    var header: String {
        switch self {
        case .associated: "注音…"
        case .details: "候選字與說明"
        default: ""
        }
    }

    @MainActor var entries: [Candidate] {
        switch self {
        case .candidates:
            return [
                "小麥注音", "注音", "因", "音", "陰", "姻", "殷", "茵", "慇",
                "氤", "痕", "暗", "壅", "湮", "惜", "裡", "絪", "袒",
                "闇", "駰", "銦", "蔭", "諳", "垔", "馨", "洇", "湮", "愔", "禋", "絪",
            ].map { Candidate(displayString: $0) }
        case .associated:
            return ["輸入法", "符號", "字母"].map {
                Candidate(displayString: $0, detail: "⇧ ⏎")
            }
        case .plainAssociated:
            return ["輸入法", "符號", "字母", "鍵盤", "練習", "教學", "標示", "系統",
                "查詢", "轉換", "設定", "工具"].map { Candidate(displayString: $0) }
        case .numbers:
            return ["一百二十三", "壹佰貳拾參", "CXXIII"].map { Candidate(displayString: $0) }
        case .icu:
            let input = "taiwan"
            let transforms: [StringTransform] = [
                .latinToHiragana, .latinToKatakana, .latinToHangul, .latinToThai,
                .latinToGreek, StringTransform("Latin-Cyrillic"), .latinToArabic,
                .latinToHebrew, StringTransform("Latin-Devanagari"),
            ]
            var results: [String] = []
            for transform in transforms {
                if let text = input.applyingTransform(transform, reverse: false),
                    text != input, !results.contains(text) {
                    results.append(text)
                }
            }
            return results.map { Candidate(displayString: $0) }
        case .details:
            return [
                Candidate(displayString: "注音", detail: "ㄓㄨˋ ㄧㄣ"),
                Candidate(displayString: "輸入法", detail: "input method"),
                Candidate(displayString: "沒有說明"),
                Candidate(displayString: "長篇說明",
                    detail: "這是一段超過候選視窗寬度的說明，用來查看截斷結果"),
            ]
        case .shortList:
            return Array(PreviewSample.candidates.entries.prefix(5))
        case .longList:
            return (1...201).map { Candidate(displayString: "選字\($0)", detail: "說明") }
        }
    }
}
