import Foundation

public struct TronAddress: Address, Hashable {
    public static let size = 20
    public static let prefix: UInt8 = 0x41

    public let data: Data

    public static func isValid(data: Data) -> Bool {
        data.count == size + 1 && data.first == prefix
    }

    public static func isValid(string: String) -> Bool {
        guard let decoded = TRXCrypto.base58Decode(string) else {
            return false
        }
        return isValid(data: decoded) && string.hasPrefix("T")
    }

    public init?(data: Data) {
        guard Self.isValid(data: data) else {
            return nil
        }
        self.data = data
    }

    public init?(string: String) {
        guard let decoded = TRXCrypto.base58Decode(string) else {
            return nil
        }
        self.init(data: decoded)
    }

    public init?(publicKey: PublicKey) {
        guard publicKey.data.count == PublicKey.uncompressedSize else {
            return nil
        }

        let hash = Data([Self.prefix]) + TRXCrypto.keccak256(publicKey.data.dropFirst()).suffix(Self.size)
        self.init(data: hash)
    }

    public var base58String: String {
        TRXCrypto.base58Encode(data)
    }

    public var description: String {
        base58String
    }
}

public struct TronAddressTestnet: Address, Hashable {
    public static let size = 20
    public static let prefix: UInt8 = 0xA0

    public let data: Data

    public static func isValid(data: Data) -> Bool {
        data.count == size + 1 && data.first == prefix
    }

    public static func isValid(string: String) -> Bool {
        guard let decoded = TRXCrypto.base58Decode(string) else {
            return false
        }
        return isValid(data: decoded)
    }

    public init?(data: Data) {
        guard Self.isValid(data: data) else {
            return nil
        }
        self.data = data
    }

    public init?(string: String) {
        guard let decoded = TRXCrypto.base58Decode(string) else {
            return nil
        }
        self.init(data: decoded)
    }

    public init?(publicKey: PublicKey) {
        guard publicKey.data.count == PublicKey.uncompressedSize else {
            return nil
        }

        let hash = Data([Self.prefix]) + TRXCrypto.keccak256(publicKey.data.dropFirst()).suffix(Self.size)
        self.init(data: hash)
    }

    public var base58String: String {
        TRXCrypto.base58Encode(data)
    }

    public var description: String {
        base58String
    }
}
