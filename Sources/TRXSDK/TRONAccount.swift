import Foundation

public final class TRONAccount {
    public let privateKey: Data
    public let publicKey: Data
    public let address: String
    public let addressData: Data
    public let addressTestnet: String

    public convenience init() throws {
        try self.init(privateKey: PrivateKey())
    }

    public convenience init(privateKeyHex: String) throws {
        let privateKeyData = try Data(hexString: privateKeyHex)
        guard let privateKey = PrivateKey(data: privateKeyData) else {
            throw TRXSDKError.invalidPrivateKey
        }
        try self.init(privateKey: privateKey)
    }

    public convenience init(privateKeyData: Data) throws {
        guard let privateKey = PrivateKey(data: privateKeyData) else {
            throw TRXSDKError.invalidPrivateKey
        }
        try self.init(privateKey: privateKey)
    }

    private init(privateKey: PrivateKey) throws {
        let publicKey = try privateKey.publicKey()
        guard let mainnetAddress = TronAddress(publicKey: publicKey),
              let testnetAddress = TronAddressTestnet(publicKey: publicKey) else {
            throw TRXSDKError.invalidPublicKey
        }

        self.privateKey = privateKey.data
        self.publicKey = publicKey.data
        self.address = mainnetAddress.base58String
        self.addressData = mainnetAddress.data
        self.addressTestnet = testnetAddress.base58String
    }

    public static func addressData(address: String) -> Data {
        TronAddress(string: address)?.data ?? Data()
    }
}

public final class TRONAddress {
    public let address: String

    public init?(string: String) {
        guard let tronAddress = TronAddress(string: string) else {
            return nil
        }
        address = tronAddress.base58String
    }

    public init?(data: Data) {
        guard let tronAddress = TronAddress(data: data) else {
            return nil
        }
        address = tronAddress.base58String
    }
}
