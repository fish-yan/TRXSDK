import Foundation

enum Base58 {
    private static let alphabet = Array("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz".utf8)
    private static let indexes: [UInt8: Int] = {
        var values: [UInt8: Int] = [:]
        for (index, byte) in alphabet.enumerated() {
            values[byte] = index
        }
        return values
    }()

    static func encode(_ data: Data) -> String {
        guard !data.isEmpty else {
            return ""
        }

        var bytes = Array(data)
        let leadingZeros = bytes.prefix { $0 == 0 }.count
        var encoded: [UInt8] = []
        var startIndex = leadingZeros

        while startIndex < bytes.count {
            var remainder = 0
            for index in startIndex..<bytes.count {
                let value = Int(bytes[index]) + remainder * 256
                bytes[index] = UInt8(value / 58)
                remainder = value % 58
            }
            encoded.append(alphabet[remainder])

            while startIndex < bytes.count && bytes[startIndex] == 0 {
                startIndex += 1
            }
        }

        encoded.append(contentsOf: Array(repeating: alphabet[0], count: leadingZeros))
        return String(bytes: encoded.reversed(), encoding: .ascii) ?? ""
    }

    static func decode(_ string: String) -> Data? {
        guard !string.isEmpty else {
            return Data()
        }

        let input = Array(string.utf8)
        let leadingZeros = input.prefix { $0 == alphabet[0] }.count
        var decoded = [UInt8](repeating: 0, count: input.count)
        var decodedLength = 0

        for byte in input {
            guard let digit = indexes[byte] else {
                return nil
            }

            var carry = digit
            var index = 0
            while index < decodedLength {
                let value = Int(decoded[index]) * 58 + carry
                decoded[index] = UInt8(value & 0xff)
                carry = value >> 8
                index += 1
            }

            while carry > 0 {
                decoded[decodedLength] = UInt8(carry & 0xff)
                decodedLength += 1
                carry >>= 8
            }
        }

        var result = Data(repeating: 0, count: leadingZeros)
        result.append(contentsOf: decoded.prefix(decodedLength).reversed())
        return result
    }
}
