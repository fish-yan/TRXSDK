import CryptoSwift
import ed25519swift
import Foundation
import secp256k1
import Security

public enum TRXCrypto {
    public static func randomBytes(count: Int) throws -> Data {
        var data = Data(count: count)
        let result = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, count, $0.baseAddress!)
        }
        guard result == errSecSuccess else {
            throw TRXSDKError.invalidPrivateKey
        }
        return data
    }

    public static func secp256k1PublicKey(from privateKey: Data, compressed: Bool = false) throws -> Data {
        let format: secp256k1.Format = compressed ? .compressed : .uncompressed
        let key = try secp256k1.Signing.PrivateKey(rawRepresentation: privateKey, format: format)
        return key.publicKey.rawRepresentation
    }

    public static func ed25519PublicKey(from privateKey: Data) -> Data {
        Data(Ed25519.calcPublicKey(secretKey: Array(privateKey)))
    }

    public static func sign(hash: Data, privateKey: Data) throws -> Data {
        guard hash.count == 32 else {
            throw TRXSDKError.invalidAmount("Hash must be 32 bytes")
        }

        let key = try secp256k1.Signing.PrivateKey(rawRepresentation: privateKey, format: .uncompressed)
        let signature = try key.ecdsa.recoverableSignature(for: HashDigest(Array(hash))).compactRepresentation
        var data = signature.signature
        data.append(UInt8(signature.recoveryId))
        return data
    }

    public static func signAsDER(hash: Data, privateKey: Data) throws -> Data {
        guard hash.count == 32 else {
            throw TRXSDKError.invalidAmount("Hash must be 32 bytes")
        }

        let key = try secp256k1.Signing.PrivateKey(rawRepresentation: privateKey, format: .uncompressed)
        return try key.ecdsa.signature(for: HashDigest(Array(hash))).derRepresentation
    }

    public static func verify(signature: Data, message: Data, publicKey: Data) throws -> Bool {
        guard message.count == 32 else {
            throw TRXSDKError.invalidAmount("Message digest must be 32 bytes")
        }

        let compactSignature: Data
        if signature.count == 65 {
            compactSignature = signature.dropLast()
        } else if signature.count == 64 {
            compactSignature = signature
        } else {
            throw TRXSDKError.invalidSignature
        }

        let format: secp256k1.Format = publicKey.count == 33 ? .compressed : .uncompressed
        let verifyingKey = try secp256k1.Signing.PublicKey(rawRepresentation: publicKey, format: format)
        let parsedSignature = try secp256k1.Signing.ECDSASignature(compactRepresentation: compactSignature)
        return verifyingKey.ecdsa.isValidSignature(parsedSignature, for: HashDigest(Array(message)))
    }

    public static func recoverPublicKey(from signature: Data, message: Data) throws -> Data {
        guard message.count == 32 else {
            throw TRXSDKError.invalidAmount("Message digest must be 32 bytes")
        }

        guard signature.count == 65, let recoveryID = signature.last else {
            throw TRXSDKError.invalidSignature
        }

        let compactSignature = signature.dropLast()
        let parsedSignature = try secp256k1.Recovery.ECDSASignature(
            compactRepresentation: compactSignature,
            recoveryId: Int32(recoveryID)
        )
        return try secp256k1.Recovery.PublicKey(
            HashDigest(Array(message)),
            signature: parsedSignature,
            format: .uncompressed
        ).rawRepresentation
    }

    public static func keccak256(_ data: Data) -> Data {
        data.sha3(.keccak256)
    }

    public static func sha3_256(_ data: Data) -> Data {
        data.sha3(.sha256)
    }

    public static func sha256(_ data: Data) -> Data {
        data.sha256()
    }

    public static func sha256sha256(_ data: Data) -> Data {
        sha256(sha256(data))
    }

    public static func base58Encode(_ data: Data) -> String {
        let payload = data + sha256sha256(data).prefix(4)
        return Base58.encode(payload)
    }

    public static func base58EncodeRaw(_ data: Data) -> String {
        Base58.encode(data)
    }

    public static func base58Decode(_ string: String) -> Data? {
        guard let data = Base58.decode(string), data.count >= 4 else {
            return nil
        }

        let payload = data.dropLast(4)
        let checksum = data.suffix(4)
        guard sha256sha256(payload).prefix(4) == checksum else {
            return nil
        }
        return Data(payload)
    }

    public static func base58DecodeRaw(_ string: String) -> Data? {
        Base58.decode(string)
    }
}
