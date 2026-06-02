import Foundation

public struct PublicKey: Hashable, CustomStringConvertible {
    public static let compressedSize = 33
    public static let uncompressedSize = 65

    public let data: Data

    public static func isValid(data: Data) -> Bool {
        switch data.first {
        case 2, 3:
            return data.count == compressedSize
        case 4, 6, 7:
            return data.count == uncompressedSize
        default:
            return false
        }
    }

    public var isCompressed: Bool {
        data.count == Self.compressedSize && (data[0] == 2 || data[0] == 3)
    }

    public var compressed: PublicKey {
        if isCompressed {
            return self
        }
        let prefix: UInt8 = 0x02 | (data[64] & 0x01)
        return PublicKey(data: Data([prefix]) + data[1..<33])!
    }

    public init?(data: Data) {
        guard Self.isValid(data: data) else {
            return nil
        }
        self.data = data
    }

    public var description: String {
        data.trxHexString
    }
}
