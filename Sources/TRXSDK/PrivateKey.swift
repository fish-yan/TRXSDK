import Foundation
import secp256k1

public final class PrivateKey: Hashable, CustomStringConvertible {
    public static let size = 32

    public private(set) var data: Data

    public static func isValid(data: Data) -> Bool {
        guard data.count == size, data.contains(where: { $0 != 0 }) else {
            return false
        }
        return (try? secp256k1.Signing.PrivateKey(rawRepresentation: data)) != nil
    }

    public init() {
        let key = try! secp256k1.Signing.PrivateKey(format: .uncompressed)
        data = key.rawRepresentation
    }

    public init?(data: Data) {
        guard Self.isValid(data: data) else {
            return nil
        }
        self.data = Data(data)
    }

    deinit {
        data.clear()
    }

    public func publicKey(compressed: Bool = false) throws -> PublicKey {
        let publicKeyData = try TRXCrypto.secp256k1PublicKey(from: data, compressed: compressed)
        guard let publicKey = PublicKey(data: publicKeyData) else {
            throw TRXSDKError.invalidPublicKey
        }
        return publicKey
    }

    public func sign(hash: Data) throws -> Data {
        try TRXCrypto.sign(hash: hash, privateKey: data)
    }

    public func signAsDER(hash: Data) throws -> Data {
        try TRXCrypto.signAsDER(hash: hash, privateKey: data)
    }

    public var description: String {
        data.trxHexString
    }

    public static func == (lhs: PrivateKey, rhs: PrivateKey) -> Bool {
        lhs.data == rhs.data
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
    }
}
