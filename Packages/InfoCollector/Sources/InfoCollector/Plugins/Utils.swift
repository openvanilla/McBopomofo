import Carbon

func osStatusToString(_ status: OSStatus) -> String {
    let bigEndianValue = status.bigEndian
    let data = withUnsafeBytes(of: bigEndianValue) { Data($0) }

    if let fourCharString = String(data: data, encoding: .ascii) {
        return fourCharString
    } else {
        return "(\(String(format: "%08X", status)))"
    }
}

func numberToHex<T: FixedWidthInteger>(_ number: T, withPrefix prefix: Bool = true) -> String {
    let width = MemoryLayout<T>.size * 2
    let formatString = prefix ? "%#0\(width + 2)X" : "%0\(width)X"
    return String(format: formatString, number.littleEndian as! CVarArg)
}
