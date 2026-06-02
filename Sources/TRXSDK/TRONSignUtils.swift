import Foundation
import SwiftProtobuf

public enum TRONSignUtils {
    public static func signTransaction(
        _ transaction: Protocol_Transaction,
        privateKey: Data
    ) throws -> Protocol_Transaction {
        var transaction = transaction
        let hash = TRXCrypto.sha256(try transaction.rawData.serializedData())
        let signature = try TRXCrypto.sign(hash: hash, privateKey: privateKey)
        transaction.signature.append(signature)
        return transaction
    }

    public static func txHash(_ transaction: Protocol_Transaction) throws -> String {
        try TRXCrypto.sha256(transaction.rawData.serializedData()).trxHexString
    }

    public static func signTransactionHash(_ messageData: Data, privateKey: Data) throws -> String {
        try "0x" + TRXCrypto.sign(hash: messageData, privateKey: privateKey).trxHexString
    }

    public static func signMessage(_ messageData: Data, isHash: Bool, privateKey: Data) throws -> String {
        let hash = isHash ? messageData : messageDigest(messageData)
        var signature = try TRXCrypto.sign(hash: hash, privateKey: privateKey)
        guard let recoveryID = signature.last else {
            throw TRXSDKError.invalidSignature
        }
        signature.removeLast()
        signature.append(recoveryID + 27)
        return "0x" + signature.trxHexString
    }

    public static func messageDigest(_ messageData: Data) -> Data {
        var data = Data()
        data.appendUInt8(0x19)
        data.append(Data("TRON Signed Message:\n32".utf8))
        data.append(messageData)
        return TRXCrypto.keccak256(data)
    }
}
