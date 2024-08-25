#!/usr/bin/env swift

// Run: `swift inspect.swift` under command line`

import CoreFoundation
import Foundation

enum CharCodeError: Error, LocalizedError {
  case invalidLength
  case notFound

  var errorDescription: String? {
    return switch self {
    case .invalidLength:
      "Length of the input string is invalid"
    case .notFound:
      "The string is not found in the current encoding"
    }
  }
}

let kCFStringEncodingBig5 = UInt32(0x0A03)
let kCFStringEncodingBig5_HKSCS_1999 = UInt32(0x0A06)
let kCFStringEncodingCNS_11643_92_P3 = UInt32(0x0653)

func getCharCode(string: String, encoding: UInt32) throws -> String {
  if string.count != 1 {
    throw CharCodeError.invalidLength
  }
  //   return string.map { c in
  let c = string.first!
  let swiftString = "\(c)"
  let cfString: CFString = swiftString as CFString
  var cStringBuffer = [CChar](repeating: 0, count: 4)
  CFStringGetCString(cfString, &cStringBuffer, 4, encoding)
  let data = Data(bytes: cStringBuffer, count: strlen(cStringBuffer))
  if data.count >= 2 {
    return "0x" + String(format: "%02x%02x", data[0], data[1]).uppercased()
  }
  throw CharCodeError.notFound
}

func main() throws {
  let path = "../BPMFBase.txt"
  let url = URL(fileURLWithPath: path)
  let text = try String(contentsOf: url, encoding: .utf8)
  let components = text.components(separatedBy: "\n")
  for line in components {
    let parts = line.components(separatedBy: " ")
    if parts.count != 5 {
      continue
    }
    let word = parts[0]
    let category = parts[4]
    let big5Code = try? getCharCode(string: word, encoding: kCFStringEncodingBig5)
    let big5HKSCScode = try? getCharCode(string: word, encoding: kCFStringEncodingBig5_HKSCS_1999)
    let cnsCode = try? getCharCode(string: word, encoding: kCFStringEncodingCNS_11643_92_P3)
    if category == "big5" {
      if big5Code == nil && big5HKSCScode == nil {
        print("\(word) is not in big5 and big5 HKSCS")
      }
    } else if category == "cns" {
      if cnsCode != nil {
        print("\(word) is not CNS")
      }
      if big5Code != nil {
        print("\(word) is in Big5 encoding")
      } else if big5HKSCScode != "N/A" {
        print("\(word) is in big5 HKSCS encoding")
      }
    } else if category == "utf8" {
      if big5Code != nil {
        print("\(word) is in big5 encoding")
      } else if big5HKSCScode != "N/A" {
        print("\(word) is in big5 HKSCS encoding")
      } else if cnsCode != nil {
        print("\(word) is in CNS")
      }
    }
  }
}

try? main()
