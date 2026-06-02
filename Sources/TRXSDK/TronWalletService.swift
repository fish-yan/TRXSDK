import Foundation
import SwiftProtobuf

public struct TronNodeResult: Equatable {
    public var success: Bool
    public var code: Int
    public var message: Data

    public init(success: Bool, code: Int = 0, message: Data = Data()) {
        self.success = success
        self.code = code
        self.message = message
    }
}

public struct TronTransactionExtension: Equatable {
    public var transaction: Protocol_Transaction
    public var txid: Data
    public var constantResult: [Data]
    public var result: TronNodeResult

    public init(
        transaction: Protocol_Transaction = Protocol_Transaction(),
        txid: Data = Data(),
        constantResult: [Data] = [],
        result: TronNodeResult = TronNodeResult(success: true)
    ) {
        self.transaction = transaction
        self.txid = txid
        self.constantResult = constantResult
        self.result = result
    }
}

public struct TronAccountResourceMessage: Equatable {
    public var freeNetUsed: Int64
    public var freeNetLimit: Int64
    public var netUsed: Int64
    public var netLimit: Int64
    public var totalNetLimit: Int64
    public var totalNetWeight: Int64
    public var energyUsed: Int64
    public var energyLimit: Int64
    public var totalEnergyLimit: Int64
    public var totalEnergyWeight: Int64
    public var storageUsed: Int64
    public var storageLimit: Int64

    public init(
        freeNetUsed: Int64 = 0,
        freeNetLimit: Int64 = 0,
        netUsed: Int64 = 0,
        netLimit: Int64 = 0,
        totalNetLimit: Int64 = 0,
        totalNetWeight: Int64 = 0,
        energyUsed: Int64 = 0,
        energyLimit: Int64 = 0,
        totalEnergyLimit: Int64 = 0,
        totalEnergyWeight: Int64 = 0,
        storageUsed: Int64 = 0,
        storageLimit: Int64 = 0
    ) {
        self.freeNetUsed = freeNetUsed
        self.freeNetLimit = freeNetLimit
        self.netUsed = netUsed
        self.netLimit = netLimit
        self.totalNetLimit = totalNetLimit
        self.totalNetWeight = totalNetWeight
        self.energyUsed = energyUsed
        self.energyLimit = energyLimit
        self.totalEnergyLimit = totalEnergyLimit
        self.totalEnergyWeight = totalEnergyWeight
        self.storageUsed = storageUsed
        self.storageLimit = storageLimit
    }
}

public protocol TronNodeClientProtocol {
    func getAccount(_ request: Protocol_Account) async throws -> Protocol_Account
    func getAccountResource(_ request: Protocol_Account) async throws -> TronAccountResourceMessage
    func createTransaction(_ request: Protocol_TransferContract) async throws -> Protocol_Transaction
    func broadcastTransaction(_ request: Protocol_Transaction) async throws -> TronNodeResult
    func transferAsset(_ request: Protocol_TransferAssetContract) async throws -> TronTransactionExtension
    func triggerContract(_ request: Protocol_TriggerSmartContract) async throws -> TronTransactionExtension
    func freezeBalance(_ request: Protocol_FreezeBalanceContract) async throws -> TronTransactionExtension
    func unfreezeBalance(_ request: Protocol_UnfreezeBalanceContract) async throws -> TronTransactionExtension
}

public final class TronWalletService {
    public static let shared = TronWalletService()

    public private(set) var fullNode: String?
    public var client: TronNodeClientProtocol?

    public init(client: TronNodeClientProtocol? = nil) {
        self.client = client
    }

    public func setupService(fullNode: String) {
        self.fullNode = fullNode
        if let client = try? TronNodeClient(fullNode: fullNode) {
            self.client = client
        }
    }

    public func getAccountResource(address: String) async throws -> TRONAccountResource {
        let resource = try await requireClient().getAccountResource(accountRequest(address: address))
        return TRONAccountResource(
            freeNetUsed: String(resource.freeNetUsed),
            freeNetLimit: String(resource.freeNetLimit),
            netUsed: String(resource.netUsed),
            netLimit: String(resource.netLimit),
            totalNetLimit: String(resource.totalNetLimit),
            totalNetWeight: String(resource.totalNetWeight),
            energyUsed: String(resource.energyUsed),
            energyLimit: String(resource.energyLimit),
            totalEnergyLimit: String(resource.totalEnergyLimit),
            totalEnergyWeight: String(resource.totalEnergyWeight),
            storageUsed: String(resource.storageUsed),
            storageLimit: String(resource.storageLimit)
        )
    }

    public func getAccount(address: String) async throws -> (account: Protocol_Account, resource: TRONAccountResource) {
        let account = try await requireClient().getAccount(accountRequest(address: address))
        return (account, accountResource(from: account))
    }

    public func createTransaction(from: String, to: String, amount: String) async throws -> Protocol_Transaction {
        let contract = try transferContract(from: from, to: to, amount: amount)
        return try await requireClient().createTransaction(contract)
    }

    public func broadcastTransaction(_ transaction: Protocol_Transaction) async throws -> String {
        let response = try await requireClient().broadcastTransaction(transaction)
        guard response.success else {
            throw error(from: response)
        }
        return try TRONSignUtils.txHash(transaction)
    }

    public func transferAsset(assetName: String, from: String, to: String, amount: String) async throws -> TronTransactionExtension {
        let contract = try transferAssetContract(assetName: assetName, from: from, to: to, amount: amount)
        return try checkedExtension(try await requireClient().transferAsset(contract))
    }

    public func transferTRC20Asset(
        assetAddress: String,
        from: String,
        to: String,
        amount: String,
        decimals: Int
    ) async throws -> TronTransactionExtension {
        let contract = try triggerContract(
            assetAddress: assetAddress,
            owner: from,
            callValue: 0,
            data: TronABI.encodeTRC20Transfer(to: to, amount: amount, decimals: decimals)
        )
        return try checkedExtension(try await requireClient().triggerContract(contract), feeLimit: 1_000_000_000)
    }

    public func transferTRC721Asset(
        assetAddress: String,
        from: String,
        to: String,
        tokenID: String
    ) async throws -> TronTransactionExtension {
        let contract = try triggerContract(
            assetAddress: assetAddress,
            owner: from,
            callValue: 0,
            data: TronABI.encodeTRC721SafeTransferFrom(from: from, to: to, tokenID: tokenID)
        )
        return try checkedExtension(try await requireClient().triggerContract(contract), feeLimit: 1_000_000_000)
    }

    public func approveTRC20Assets(
        assetAddress: String,
        from: String,
        to: String,
        amount: String,
        decimals: Int
    ) async throws -> TronTransactionExtension {
        let contract = try triggerContract(
            assetAddress: assetAddress,
            owner: from,
            callValue: 0,
            data: TronABI.encodeTRC20Approve(spender: to, amount: amount, decimals: decimals)
        )
        return try checkedExtension(try await requireClient().triggerContract(contract), feeLimit: 1_000_000_000)
    }

    public func checkAllowanceTRC20Assets(
        assetAddress: String,
        from: String,
        to: String
    ) async throws -> TronTransactionExtension {
        let contract = try triggerContract(
            assetAddress: assetAddress,
            owner: from,
            callValue: 0,
            data: TronABI.encodeTRC20Allowance(owner: from, spender: to)
        )
        return try checkedExtension(try await requireClient().triggerContract(contract))
    }

    public func balanceOf(assetAddress: String, owner: String) async throws -> TronTransactionExtension {
        let contract = try triggerContract(
            assetAddress: assetAddress,
            owner: owner,
            callValue: 0,
            data: TronABI.encodeTRC20BalanceOf(owner: owner)
        )
        return try checkedExtension(try await requireClient().triggerContract(contract))
    }

    public func sendSwapTRC20Assets(
        assetAddress: String,
        from: String,
        txHash: String,
        amount: String,
        decimals: Int
    ) async throws -> TronTransactionExtension {
        let contract = try triggerContract(
            assetAddress: assetAddress,
            owner: from,
            callValue: TronAmount.scaledInt64(amount, decimals: decimals),
            data: Data(hexString: txHash)
        )
        return try checkedExtension(try await requireClient().triggerContract(contract), feeLimit: 100_000_000)
    }

    public func freezeBalance(
        address: String,
        amount: String,
        resourceCode: Protocol_ResourceCode
    ) async throws -> TronTransactionExtension {
        var contract = Protocol_FreezeBalanceContract()
        contract.ownerAddress = try addressData(address)
        contract.frozenBalance = try TronAmount.scaledInt64(amount, decimals: 6)
        contract.frozenDuration = 3
        contract.resource = resourceCode
        return try checkedExtension(try await requireClient().freezeBalance(contract))
    }

    public func unfreezeBalance(
        address: String,
        resourceCode: Protocol_ResourceCode
    ) async throws -> TronTransactionExtension {
        var contract = Protocol_UnfreezeBalanceContract()
        contract.ownerAddress = try addressData(address)
        contract.resource = resourceCode
        return try checkedExtension(try await requireClient().unfreezeBalance(contract))
    }

    public func transferContract(from: String, to: String, amount: String) throws -> Protocol_TransferContract {
        var contract = Protocol_TransferContract()
        contract.ownerAddress = try addressData(from)
        contract.toAddress = try addressData(to)
        contract.amount = try TronAmount.scaledInt64(amount, decimals: 6)
        return contract
    }

    public func transferAssetContract(assetName: String, from: String, to: String, amount: String) throws -> Protocol_TransferAssetContract {
        var contract = Protocol_TransferAssetContract()
        contract.ownerAddress = try addressData(from)
        contract.toAddress = try addressData(to)
        contract.amount = Int64(amount) ?? 0
        contract.assetName = Data(assetName.utf8)
        return contract
    }

    public func triggerContract(assetAddress: String, owner: String, callValue: Int64, data: Data) throws -> Protocol_TriggerSmartContract {
        var contract = Protocol_TriggerSmartContract()
        contract.ownerAddress = try addressData(owner)
        contract.contractAddress = try addressData(assetAddress)
        contract.callValue = callValue
        contract.data = data
        return contract
    }

    private func accountRequest(address: String) throws -> Protocol_Account {
        var account = Protocol_Account()
        account.address = try addressData(address)
        return account
    }

    private func addressData(_ address: String) throws -> Data {
        guard let data = TronAddress(string: address)?.data else {
            throw TRXSDKError.invalidAddress(address)
        }
        return data
    }

    private func accountResource(from account: Protocol_Account) -> TRONAccountResource {
        let frozenNet = account.frozen.reduce(Int64(0)) { $0 + $1.frozenBalance }
        let expireTimeNet = account.frozen.map(\.expireTime).max() ?? 0
        let frozenEnergy = account.accountResource.frozenBalanceForEnergy.frozenBalance
        let expireTimeEnergy = account.accountResource.frozenBalanceForEnergy.expireTime
        let now = Int64(Date().timeIntervalSince1970 * 1000)

        return TRONAccountResource(
            availableBalance: TronAmount.trxFromSun(String(account.balance)),
            frozenBalance: TronAmount.trxFromSun(String(frozenNet + frozenEnergy)),
            totalBalance: TronAmount.trxFromSun(String(account.balance + frozenNet + frozenEnergy)),
            frozenNet: TronAmount.trxFromSun(String(frozenNet)),
            frozenEnergy: TronAmount.trxFromSun(String(frozenEnergy)),
            expireTimeNet: expireTimeNet,
            expireTimeEnergy: expireTimeEnergy,
            canUnfreezeNet: now > expireTimeNet,
            canUnfreezeEnergy: now > expireTimeEnergy
        )
    }

    private func checkedExtension(
        _ extensionResult: TronTransactionExtension,
        feeLimit: Int64? = nil
    ) throws -> TronTransactionExtension {
        guard extensionResult.result.success else {
            throw error(from: extensionResult.result)
        }

        var extensionResult = extensionResult
        if let feeLimit {
            extensionResult.transaction.rawData.feeLimit = feeLimit
        }
        return extensionResult
    }

    private func requireClient() throws -> TronNodeClientProtocol {
        guard let client else {
            throw TRXSDKError.missingClient
        }
        return client
    }

    private func error(from result: TronNodeResult) -> TRXSDKError {
        let reason = String(data: result.message, encoding: .utf8) ?? "TRON node rejected the request"
        return .nodeRejected(code: result.code, reason: reason)
    }
}
