import Foundation
import SwiftProtobuf

public enum TRXDappContractShowType: Equatable {
    case unknown
    case transfer
}

public enum TRONUtils {
    public static func trxFromSun(_ sun: String) -> String {
        TronAmount.trxFromSun(sun)
    }

    public static func sunFromTRX(_ trx: String) throws -> String {
        try TronAmount.sunFromTRX(trx)
    }

    public static func transaction(with dictionary: [String: Any]) throws -> Protocol_Transaction {
        guard
            let rawDictionary = dictionary["raw_data"] as? [String: Any],
            let contractDictionaries = rawDictionary["contract"] as? [[String: Any]],
            let firstContract = contractDictionaries.first,
            let parameter = firstContract["parameter"] as? [String: Any],
            let value = parameter["value"] as? [String: Any],
            let type = firstContract["type"] as? String
        else {
            throw TRXSDKError.unsupportedTransactionContract("missing raw_data.contract")
        }

        var rawData = Protocol_Transaction.raw()
        rawData.refBlockBytes = try dataValue(rawDictionary["ref_block_bytes"])
        rawData.refBlockHash = try dataValue(rawDictionary["ref_block_hash"])
        rawData.timestamp = int64Value(rawDictionary["timestamp"])
        rawData.expiration = int64Value(rawDictionary["expiration"])
        rawData.feeLimit = int64Value(rawDictionary["fee_limit"])

        var contract = Protocol_Transaction.Contract()
        switch type {
        case "TransferContract", "Protocol_TransferContract":
            var transferContract = Protocol_TransferContract()
            transferContract.ownerAddress = try dataValue(value["owner_address"])
            transferContract.toAddress = try dataValue(value["to_address"])
            transferContract.amount = int64Value(value["amount"])
            contract.type = .transferContract
            contract.parameter = try packedAny(transferContract, typeURL: parameter["type_url"] as? String)

        case "TransferAssetContract", "Protocol_TransferAssetContract":
            var transferAssetContract = Protocol_TransferAssetContract()
            transferAssetContract.ownerAddress = try dataValue(value["owner_address"])
            transferAssetContract.toAddress = try dataValue(value["to_address"])
            transferAssetContract.amount = int64Value(value["amount"])
            transferAssetContract.assetName = try dataValue(value["asset_name"])
            contract.type = .transferAssetContract
            contract.parameter = try packedAny(transferAssetContract, typeURL: parameter["type_url"] as? String)

        case "TriggerSmartContract", "Protocol_TriggerSmartContract":
            var triggerSmartContract = Protocol_TriggerSmartContract()
            triggerSmartContract.ownerAddress = try dataValue(value["owner_address"])
            triggerSmartContract.contractAddress = try dataValue(value["contract_address"])
            triggerSmartContract.callValue = int64Value(value["call_value"])
            triggerSmartContract.data = try dataValue(value["data"])
            contract.type = .triggerSmartContract
            contract.parameter = try packedAny(triggerSmartContract, typeURL: parameter["type_url"] as? String)

        case "FreezeBalanceContract", "Protocol_FreezeBalanceContract":
            var freezeBalanceContract = Protocol_FreezeBalanceContract()
            freezeBalanceContract.ownerAddress = try dataValue(value["owner_address"])
            freezeBalanceContract.frozenBalance = int64Value(value["frozen_balance"])
            freezeBalanceContract.frozenDuration = int64Value(value["frozen_duration"])
            freezeBalanceContract.resource = resourceCode(value["resource"])
            contract.type = .freezeBalanceContract
            contract.parameter = try packedAny(freezeBalanceContract, typeURL: parameter["type_url"] as? String)

        case "UnfreezeBalanceContract", "Protocol_UnfreezeBalanceContract":
            var unfreezeBalanceContract = Protocol_UnfreezeBalanceContract()
            unfreezeBalanceContract.ownerAddress = try dataValue(value["owner_address"])
            unfreezeBalanceContract.resource = resourceCode(value["resource"])
            contract.type = .unfreezeBalanceContract
            contract.parameter = try packedAny(unfreezeBalanceContract, typeURL: parameter["type_url"] as? String)

        case "VoteWitnessContract", "Protocol_VoteWitnessContract":
            var voteWitnessContract = Protocol_VoteWitnessContract()
            voteWitnessContract.ownerAddress = try dataValue(value["owner_address"])
            voteWitnessContract.votes = (value["votes"] as? [[String: Any]] ?? []).map { vote in
                var protobufVote = Protocol_VoteWitnessContract.Vote()
                protobufVote.voteAddress = (try? dataValue(vote["vote_address"])) ?? Data()
                protobufVote.voteCount = int64Value(vote["vote_count"])
                return protobufVote
            }
            contract.type = .voteWitnessContract
            contract.parameter = try packedAny(voteWitnessContract, typeURL: parameter["type_url"] as? String)

        case "AccountUpdateContract", "Protocol_AccountUpdateContract":
            var accountUpdateContract = Protocol_AccountUpdateContract()
            accountUpdateContract.ownerAddress = try dataValue(value["owner_address"])
            accountUpdateContract.accountName = try dataValue(value["account_name"])
            contract.type = .accountUpdateContract
            contract.parameter = try packedAny(accountUpdateContract, typeURL: parameter["type_url"] as? String)

        case "ExchangeTransactionContract", "Protocol_ExchangeTransactionContract":
            var exchangeTransactionContract = Protocol_ExchangeTransactionContract()
            exchangeTransactionContract.ownerAddress = try dataValue(value["owner_address"])
            exchangeTransactionContract.exchangeID = int64Value(value["exchange_id"])
            exchangeTransactionContract.tokenID = try dataValue(value["token_id"])
            exchangeTransactionContract.quant = int64Value(value["quant"])
            exchangeTransactionContract.expected = int64Value(value["expected"])
            contract.type = .exchangeTransactionContract
            contract.parameter = try packedAny(exchangeTransactionContract, typeURL: parameter["type_url"] as? String)

        default:
            throw TRXSDKError.unsupportedTransactionContract(type)
        }

        rawData.contract.append(contract)
        var transaction = Protocol_Transaction()
        transaction.rawData = rawData
        transaction.signature = try (dictionary["signature"] as? [Any] ?? []).map { value in
            try dataValue(value)
        }
        return transaction
    }

    public static func transactionShowType(with transaction: Protocol_Transaction) -> TRXDappContractShowType {
        guard let contract = transaction.rawData.contract.first else {
            return .unknown
        }

        switch contract.type {
        case .transferContract, .transferAssetContract, .triggerSmartContract:
            return .transfer
        default:
            return .unknown
        }
    }

    public static func contract(with transaction: Protocol_Transaction) -> [String: Any] {
        guard let contract = transaction.rawData.contract.first else {
            return ["type": "", "value": [:]]
        }

        switch contract.type {
        case .voteWitnessContract:
            guard let voteContract = try? Protocol_VoteWitnessContract(unpackingAny: contract.parameter) else {
                return ["type": "", "value": [:]]
            }
            return [
                "type": "VoteWitnessContract",
                "value": [
                    "owner_address": voteContract.ownerAddress.trxHexString,
                    "votes": voteContract.votes.map {
                        [
                            "vote_address": $0.voteAddress.trxHexString,
                            "vote_count": $0.voteCount,
                        ]
                    },
                ],
            ]

        case .accountUpdateContract:
            guard let accountContract = try? Protocol_AccountUpdateContract(unpackingAny: contract.parameter) else {
                return ["type": "", "value": [:]]
            }
            return [
                "type": "AccountUpdateContract",
                "value": [
                    "owner_address": accountContract.ownerAddress.trxHexString,
                    "account_name": accountContract.accountName.trxHexString,
                ],
            ]

        case .exchangeTransactionContract:
            guard let exchangeContract = try? Protocol_ExchangeTransactionContract(unpackingAny: contract.parameter) else {
                return ["type": "", "value": [:]]
            }
            return [
                "type": "ExchangeTransactionContract",
                "value": [
                    "owner_address": exchangeContract.ownerAddress.trxHexString,
                    "exchange_id": exchangeContract.exchangeID,
                    "token_id": exchangeContract.tokenID.trxHexString,
                    "quant": exchangeContract.quant,
                    "expected": exchangeContract.expected,
                ],
            ]

        default:
            return ["type": "", "value": [:]]
        }
    }

    public static func transfer(with transaction: Protocol_Transaction) -> [String: String] {
        guard let contract = transaction.rawData.contract.first else {
            return ["amount": "", "to": "", "symbol": ""]
        }

        switch contract.type {
        case .transferContract:
            guard
                let transferContract = try? Protocol_TransferContract(unpackingAny: contract.parameter),
                let address = TronAddress(data: transferContract.toAddress)
            else {
                return ["amount": "", "to": "", "symbol": ""]
            }
            return [
                "amount": trxFromSun(String(transferContract.amount)),
                "to": address.base58String,
                "symbol": "TRX",
            ]

        case .transferAssetContract:
            guard
                let transferAssetContract = try? Protocol_TransferAssetContract(unpackingAny: contract.parameter),
                let address = TronAddress(data: transferAssetContract.toAddress)
            else {
                return ["amount": "", "to": "", "symbol": ""]
            }
            return [
                "amount": String(transferAssetContract.amount),
                "to": address.base58String,
                "symbol": String(data: transferAssetContract.assetName, encoding: .utf8) ?? "",
            ]

        case .triggerSmartContract:
            guard
                let triggerSmartContract = try? Protocol_TriggerSmartContract(unpackingAny: contract.parameter),
                let address = TronAddress(data: triggerSmartContract.contractAddress)
            else {
                return ["amount": "", "to": "", "symbol": ""]
            }
            return [
                "amount": trxFromSun(String(triggerSmartContract.callValue)),
                "to": address.base58String,
                "symbol": "TRX",
            ]

        default:
            return ["amount": "", "to": "", "symbol": ""]
        }
    }

    public static func toAddress(with transaction: Protocol_Transaction) -> String {
        transfer(with: transaction)["to"] ?? ""
    }

    private static func packedAny(_ message: some Message, typeURL: String?) throws -> Google_Protobuf_Any {
        var any = try Google_Protobuf_Any(message: message)
        if let typeURL, !typeURL.isEmpty {
            any.typeURL = typeURL
        }
        return any
    }

    private static func dataValue(_ value: Any?) throws -> Data {
        if let data = value as? Data {
            return data
        }
        guard let string = value as? String else {
            return Data()
        }
        return try Data(hexString: string)
    }

    private static func resourceCode(_ value: Any?) -> Protocol_ResourceCode {
        if let value = value as? Int {
            return Protocol_ResourceCode(rawValue: value) ?? .bandwidth
        }
        guard let value = value as? String else {
            return .bandwidth
        }
        return value.uppercased() == "ENERGY" ? .energy : .bandwidth
    }

    private static func int64Value(_ value: Any?) -> Int64 {
        switch value {
        case let value as Int64:
            return value
        case let value as Int:
            return Int64(value)
        case let value as UInt64:
            return Int64(value)
        case let value as NSNumber:
            return value.int64Value
        case let value as String:
            return Int64(value) ?? 0
        default:
            return 0
        }
    }
}
