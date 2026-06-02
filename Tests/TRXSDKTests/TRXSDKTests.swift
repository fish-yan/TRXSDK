import XCTest
@testable import TRXSDK

final class TRXSDKTests: XCTestCase {
    func testTRONAddressRoundTrip() throws {
        let usdtContract = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"
        let address = try XCTUnwrap(TronAddress(string: usdtContract))

        XCTAssertEqual(address.data.trxHexString, "41a614f803b6fd780986a42c78ec9c7f77e6ded13c")
        XCTAssertEqual(address.base58String, usdtContract)
    }

    func testEd25519PublicKeyUsesSwiftImplementation() throws {
        let privateKey = try Data(hexString: "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60")
        let publicKey = TRXCrypto.ed25519PublicKey(from: privateKey)

        XCTAssertEqual(publicKey.trxHexString, "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a")
    }

    func testPrivateKeyGeneratesExpectedAddress() throws {
        let privateKeyData = try Data(hexString: "6840b7af9dc1cc34ea30f0e0d5cf172d899083ca4d39664d04997dccde3d4c8a")
        let privateKey = try XCTUnwrap(PrivateKey(data: privateKeyData))
        let publicKey = try privateKey.publicKey()
        let address = try XCTUnwrap(TronAddress(publicKey: publicKey))

        XCTAssertEqual(address.base58String, "TVvZKaacpfZCHDzqWu2ksGF5Kxo8C3S1G1")
    }

    func testTRC20TransferEncoding() throws {
        let data = try TronABI.encodeTRC20Transfer(
            to: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
            amount: "1",
            decimals: 6
        )

        XCTAssertEqual(data.prefix(4).trxHexString, "a9059cbb")
        XCTAssertEqual(data.count, 68)
        XCTAssertEqual(
            data.trxHexString,
            "a9059cbb" +
                "000000000000000000000000a614f803b6fd780986a42c78ec9c7f77e6ded13c" +
                "00000000000000000000000000000000000000000000000000000000000f4240"
        )
    }

    func testTronWalletServiceGetAccount() async throws {
        let address = try XCTUnwrap(TronAddress(string: Self.usdtContractAddress))
        let client = try Self.liveNodeClient()
        let service = TronWalletService(client: client)
        let result = try await Self.retryLiveNodeCall {
            try await service.getAccount(address: address.base58String)
        }

        XCTAssertEqual(result.account.address, address.data)
        XCTAssertEqual(result.account.type, .contract)
        XCTAssertGreaterThan(result.account.balance, 0)
        XCTAssertFalse(result.account.accountName.isEmpty)
        let availableBalance = try XCTUnwrap(Decimal(string: result.resource.availableBalance))
        XCTAssertGreaterThanOrEqual(availableBalance, 0)
    }

    func testTronNodeClientGetAccountResourceUsesLiveNode() async throws {
        let owner = try XCTUnwrap(TronAddress(string: Self.usdtContractAddress))
        let client = try Self.liveNodeClient()

        var account = Protocol_Account()
        account.address = owner.data
        let resource = try await Self.retryLiveNodeCall {
            try await client.getAccountResource(account)
        }

        XCTAssertGreaterThanOrEqual(resource.freeNetUsed, 0)
        XCTAssertGreaterThan(resource.freeNetLimit, 0)
        XCTAssertGreaterThan(resource.totalNetLimit, 0)
        XCTAssertGreaterThan(resource.totalEnergyLimit, 0)
    }

    func testTronNodeClientCreateTransactionUsesLiveNode() async throws {
        let owner = try XCTUnwrap(TronAddress(string: Self.liveOwnerAddress))
        let recipient = try XCTUnwrap(TronAddress(string: Self.usdtContractAddress))
        let client = try Self.liveNodeClient()

        var contract = Protocol_TransferContract()
        contract.ownerAddress = owner.data
        contract.toAddress = recipient.data
        contract.amount = 1
        let transaction = try await Self.retryLiveNodeCall {
            try await client.createTransaction(contract)
        }
        let parsedContract: Protocol_Transaction.Contract = try XCTUnwrap(transaction.rawData.contract.first)
        let transfer = try Protocol_TransferContract(unpackingAny: parsedContract.parameter)

        XCTAssertFalse(transaction.rawData.refBlockBytes.isEmpty)
        XCTAssertFalse(transaction.rawData.refBlockHash.isEmpty)
        XCTAssertGreaterThan(transaction.rawData.expiration, 0)
        XCTAssertGreaterThan(transaction.rawData.timestamp, 0)
        XCTAssertEqual(parsedContract.type, .transferContract)
        XCTAssertEqual(transfer.ownerAddress, owner.data)
        XCTAssertEqual(transfer.toAddress, recipient.data)
        XCTAssertEqual(transfer.amount, 1)
    }

    func testTronNodeClientTriggerContractUsesLiveNode() async throws {
        let owner = try XCTUnwrap(TronAddress(string: Self.liveOwnerAddress))
        let contractAddress = try XCTUnwrap(TronAddress(string: Self.usdtContractAddress))
        let callData = try TronABI.encodeTRC20BalanceOf(owner: owner.base58String)
        let client = try Self.liveNodeClient()

        var contract = Protocol_TriggerSmartContract()
        contract.ownerAddress = owner.data
        contract.contractAddress = contractAddress.data
        contract.data = callData
        let extensionResult = try await Self.retryLiveNodeCall {
            try await client.triggerContract(contract)
        }

        XCTAssertTrue(extensionResult.result.success)
        XCTAssertEqual(try XCTUnwrap(extensionResult.constantResult.first).count, 32)
    }

    func testTronNodeClientBroadcastTransactionUsesLiveNode() async throws {
        let owner = try XCTUnwrap(TronAddress(string: Self.liveOwnerAddress))
        let recipient = try XCTUnwrap(TronAddress(string: Self.usdtContractAddress))
        let client = try Self.liveNodeClient()

        var contract = Protocol_TransferContract()
        contract.ownerAddress = owner.data
        contract.toAddress = recipient.data
        contract.amount = 1
        let transaction = try await Self.retryLiveNodeCall {
            try await client.createTransaction(contract)
        }

        let result = try await Self.retryLiveNodeCall {
            try await client.broadcastTransaction(transaction)
        }

        XCTAssertFalse(result.success)
        XCTAssertFalse(result.message.isEmpty)
    }
}

private extension TRXSDKTests {
    static let liveFullNode = "grpc.trongrid.io:50051"
    static let liveOwnerAddress = "TLa2f6VPqDgRE67v1736s7bJ8Ray5wYjU7"
    static let usdtContractAddress = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"

    static func liveNodeClient() throws -> TronNodeClient {
        try TronNodeClient(fullNode: liveFullNode)
    }

    static func retryLiveNodeCall<Value>(
        _ operation: () async throws -> Value
    ) async throws -> Value {
        var lastError: Error?

        for attempt in 1...3 {
            do {
                return try await operation()
            } catch {
                lastError = error
                guard error.isTransientGRPCError, attempt < 3 else {
                    throw error
                }
                try await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000)
            }
        }

        throw try XCTUnwrap(lastError)
    }
}

private extension Error {
    var isTransientGRPCError: Bool {
        let error = self as NSError
        guard error.domain == "TRXSDKGRPCError" else {
            return false
        }
        return error.code == 14 || error.localizedDescription.contains("Socket closed")
    }
}
