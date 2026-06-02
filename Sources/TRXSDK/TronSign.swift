import Foundation

public struct TronSign {
    private let tronTransaction: Protocol_Transaction
    public private(set) var signature: Data?

    public init(tronTransaction: Protocol_Transaction) {
        self.tronTransaction = tronTransaction
    }

    public mutating func sign(hashSigner: (Data) throws -> Data) throws {
        let data = try tronTransaction.rawData.serializedData()
        signature = try hashSigner(TRXCrypto.sha256(data))
    }
}
