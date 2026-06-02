import Foundation

public extension Data {
    init(hexString: String) throws {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("0x") || hex.hasPrefix("0X") {
            hex.removeFirst(2)
        }
        if hex.count % 2 != 0 {
            hex = "0" + hex
        }

        var data = Data(capacity: hex.count / 2)
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = hex[index..<nextIndex]
            guard let byte = UInt8(byteString, radix: 16) else {
                throw TRXSDKError.invalidHexString(hexString)
            }
            data.append(byte)
            index = nextIndex
        }
        self = data
    }

    var trxHexString: String {
        map { String(format: "%02x", $0) }.joined()
    }

    mutating func appendUInt8(_ value: UInt8) {
        append(value)
    }

    mutating func clear() {
        resetBytes(in: 0..<count)
    }

    func leftPadded(to size: Int) throws -> Data {
        guard count <= size else {
            throw TRXSDKError.amountOverflow(trxHexString)
        }
        return Data(repeating: 0, count: size - count) + self
    }
}

extension String {
    var trxDroppingHexPrefix: String {
        if hasPrefix("0x") || hasPrefix("0X") {
            return String(dropFirst(2))
        }
        return self
    }
}
