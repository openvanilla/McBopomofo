import Foundation

public enum Punctuation: String, CaseIterable {
    init?(braille: String) {
        let aCase = Punctuation.allCases.first { aCase in
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
        switch self {
        case .period:
            "⠤"
        case .dot:
            "⠤"
        case .comma:
            "⠆"
        case .semicolon:
            "⠰"
        case .ideographicComma:
            "⠠"
        case .questionMark:
            "⠕"
        case .exclamationMark:
            "⠇"
        case .colon:
            "⠒⠒"
        case .personNameMark:
            "⠰⠰"
        case .slash:
            "⠐⠂"
        case .bookNameMark:
            "⠠⠤"
        case .ellipsis:
            "⠐⠐⠐"
        case .referenceMark:
            "⠈⠼"
        case .doubleRing:
            "⠪⠕"
        case .singleQuotationMarkLeft:
            "⠰⠤"
        case .singleQuotationMarkRight:
            "⠤⠆"
        case .doubleQuotationMarkLeft:
            "⠰⠤⠰⠤"
        case .doubleQuotationMarkRight:
            "⠤⠆⠤⠆"
        case .parenthesesLeft:
            "⠪"
        case .parenthesesRight:
            "⠕"
        case .bracketLeft:
            "⠯"
        case .bracketRight:
            "⠽"
        case .braceLeft:
            "⠦"
        case .braceRight:
            "⠴"
        }
    }


    case period = "。"
    case dot = "·"
    case comma = "，"
    case semicolon = "；"
    case ideographicComma = "、"
    case questionMark = "？"
    case exclamationMark = "！"
    case colon = "："
    case personNameMark = "╴"
    case slash = "—"
    case bookNameMark = "﹏"
    case ellipsis = "…"
    case referenceMark = "※"
    case doubleRing = "◎"
    case singleQuotationMarkLeft = "「"
    case singleQuotationMarkRight = "」"
    case doubleQuotationMarkLeft = "『"
    case doubleQuotationMarkRight = "』"
    case parenthesesLeft = "（"
    case parenthesesRight = "）"
    case bracketLeft = "〔"
    case bracketRight = "〕"
    case braceLeft = "｛"
    case braceRight = "｝"
}
