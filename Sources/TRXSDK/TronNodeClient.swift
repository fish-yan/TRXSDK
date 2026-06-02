import Foundation
import SwiftProtobuf
import TRXSDKGRPC

public final class TronNodeClient: TronNodeClientProtocol {
    public let fullNode: String
    private let transport: TronNodeTransport

    public convenience init(fullNode: String) throws {
        let host = try Self.normalizedHost(fullNode)
        self.init(fullNode: host, transport: GRPCTronNodeTransport(host: host))
    }

    init(fullNode: String, transport: TronNodeTransport) {
        self.fullNode = fullNode
        self.transport = transport
    }

    public func getAccount(_ request: Protocol_Account) async throws -> Protocol_Account {
        let responseData = try await transport.getAccount(requestData: request.serializedData())
        return try Protocol_Account(serializedBytes: responseData)
    }

    public func getAccountResource(_ request: Protocol_Account) async throws -> TronAccountResourceMessage {
        try await transport.getAccountResource(requestData: request.serializedData())
    }

    public func createTransaction(_ request: Protocol_TransferContract) async throws -> Protocol_Transaction {
        let responseData = try await transport.createTransaction(requestData: request.serializedData())
        return try Protocol_Transaction(serializedBytes: responseData)
    }

    public func broadcastTransaction(_ request: Protocol_Transaction) async throws -> TronNodeResult {
        try await transport.broadcastTransaction(requestData: request.serializedData())
    }

    public func transferAsset(_ request: Protocol_TransferAssetContract) async throws -> TronTransactionExtension {
        try await transport.transferAsset(requestData: request.serializedData())
    }

    public func triggerContract(_ request: Protocol_TriggerSmartContract) async throws -> TronTransactionExtension {
        try await transport.triggerContract(requestData: request.serializedData())
    }

    public func freezeBalance(_ request: Protocol_FreezeBalanceContract) async throws -> TronTransactionExtension {
        try await transport.freezeBalance(requestData: request.serializedData())
    }

    public func unfreezeBalance(_ request: Protocol_UnfreezeBalanceContract) async throws -> TronTransactionExtension {
        try await transport.unfreezeBalance(requestData: request.serializedData())
    }
}

protocol TronNodeTransport {
    func getAccount(requestData: Data) async throws -> Data
    func getAccountResource(requestData: Data) async throws -> TronAccountResourceMessage
    func createTransaction(requestData: Data) async throws -> Data
    func broadcastTransaction(requestData: Data) async throws -> TronNodeResult
    func transferAsset(requestData: Data) async throws -> TronTransactionExtension
    func triggerContract(requestData: Data) async throws -> TronTransactionExtension
    func freezeBalance(requestData: Data) async throws -> TronTransactionExtension
    func unfreezeBalance(requestData: Data) async throws -> TronTransactionExtension
}

private final class GRPCTronNodeTransport: TronNodeTransport {
    private let client: TRXSDKGRPCClient

    init(host: String) {
        client = TRXSDKGRPCClient(host: host)
    }

    func getAccount(requestData: Data) async throws -> Data {
        try await dataResponse { completion in
            client.getAccount(requestData: requestData, completion: completion)
        }
    }

    func getAccountResource(requestData: Data) async throws -> TronAccountResourceMessage {
        let responseData = try await dataResponse { completion in
            client.getAccountResource(requestData: requestData, completion: completion)
        }
        return try TronNodeProtobufParser.accountResourceMessage(from: responseData)
    }

    func createTransaction(requestData: Data) async throws -> Data {
        try await dataResponse { completion in
            client.createTransaction(requestData: requestData, completion: completion)
        }
    }

    func broadcastTransaction(requestData: Data) async throws -> TronNodeResult {
        let responseData = try await dataResponse { completion in
            client.broadcastTransaction(requestData: requestData, completion: completion)
        }
        return try TronNodeProtobufParser.nodeResult(from: responseData, defaultSuccess: false)
    }

    func transferAsset(requestData: Data) async throws -> TronTransactionExtension {
        let responseData = try await dataResponse { completion in
            client.transferAsset(requestData: requestData, completion: completion)
        }
        return try TronNodeProtobufParser.transactionExtension(from: responseData)
    }

    func triggerContract(requestData: Data) async throws -> TronTransactionExtension {
        let responseData = try await dataResponse { completion in
            client.triggerContract(requestData: requestData, completion: completion)
        }
        return try TronNodeProtobufParser.transactionExtension(from: responseData)
    }

    func freezeBalance(requestData: Data) async throws -> TronTransactionExtension {
        let responseData = try await dataResponse { completion in
            client.freezeBalance(requestData: requestData, completion: completion)
        }
        return try TronNodeProtobufParser.transactionExtension(from: responseData)
    }

    func unfreezeBalance(requestData: Data) async throws -> TronTransactionExtension {
        let responseData = try await dataResponse { completion in
            client.unfreezeBalance(requestData: requestData, completion: completion)
        }
        return try TronNodeProtobufParser.transactionExtension(from: responseData)
    }
}

private extension GRPCTronNodeTransport {
    func dataResponse(
        _ operation: (@escaping @Sendable (Data?, Error?) -> Void) -> Void
    ) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            operation { data, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data else {
                    continuation.resume(throwing: TRXSDKError.invalidNodeResponse("Missing gRPC data response"))
                    return
                }
                continuation.resume(returning: data)
            }
        }
    }

}

private extension TronNodeClient {
    static func normalizedHost(_ fullNode: String) throws -> String {
        let trimmed = fullNode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw TRXSDKError.invalidNodeURL(fullNode)
        }

        guard let url = URL(string: trimmed), url.scheme != nil, let host = url.host else {
            return trimmed
        }

        if let port = url.port {
            return "\(host):\(port)"
        }
        return host
    }
}

private enum TronNodeProtobufParser {
    static func accountResourceMessage(from data: Data) throws -> TronAccountResourceMessage {
        var reader = ProtobufWireReader(data: data)
        var message = TronAccountResourceMessage()

        while let field = try reader.nextField() {
            switch field.number {
            case 1:
                message.freeNetUsed = Int64(try reader.readVarint())
            case 2:
                message.freeNetLimit = Int64(try reader.readVarint())
            case 3:
                message.netUsed = Int64(try reader.readVarint())
            case 4:
                message.netLimit = Int64(try reader.readVarint())
            case 7:
                message.totalNetLimit = Int64(try reader.readVarint())
            case 8:
                message.totalNetWeight = Int64(try reader.readVarint())
            case 13:
                message.energyUsed = Int64(try reader.readVarint())
            case 14:
                message.energyLimit = Int64(try reader.readVarint())
            case 15:
                message.totalEnergyLimit = Int64(try reader.readVarint())
            case 16:
                message.totalEnergyWeight = Int64(try reader.readVarint())
            case 21:
                message.storageUsed = Int64(try reader.readVarint())
            case 22:
                message.storageLimit = Int64(try reader.readVarint())
            default:
                try reader.skip(wireType: field.wireType)
            }
        }

        return message
    }

    static func transactionExtension(from data: Data) throws -> TronTransactionExtension {
        var reader = ProtobufWireReader(data: data)
        var transaction = Protocol_Transaction()
        var txid = Data()
        var constantResult: [Data] = []
        var result = TronNodeResult(success: true)

        while let field = try reader.nextField() {
            switch field.number {
            case 1:
                transaction = try Protocol_Transaction(serializedBytes: try reader.readLengthDelimitedData())
            case 2:
                txid = try reader.readLengthDelimitedData()
            case 3:
                constantResult.append(try reader.readLengthDelimitedData())
            case 4:
                result = try nodeResult(from: try reader.readLengthDelimitedData(), defaultSuccess: true)
            default:
                try reader.skip(wireType: field.wireType)
            }
        }

        return TronTransactionExtension(
            transaction: transaction,
            txid: txid,
            constantResult: constantResult,
            result: result
        )
    }

    static func nodeResult(from data: Data, defaultSuccess: Bool) throws -> TronNodeResult {
        var reader = ProtobufWireReader(data: data)
        var success = defaultSuccess
        var code = 0
        var message = Data()

        while let field = try reader.nextField() {
            switch field.number {
            case 1:
                success = try reader.readVarint() != 0
            case 2:
                code = Int(try reader.readVarint())
            case 3:
                message = try reader.readLengthDelimitedData()
            default:
                try reader.skip(wireType: field.wireType)
            }
        }

        return TronNodeResult(success: success, code: code, message: message)
    }
}

private struct ProtobufWireReader {
    struct Field {
        let number: Int
        let wireType: Int
    }

    private let bytes: [UInt8]
    private var offset = 0

    init(data: Data) {
        bytes = Array(data)
    }

    var isAtEnd: Bool {
        offset >= bytes.count
    }

    mutating func nextField() throws -> Field? {
        guard !isAtEnd else {
            return nil
        }

        let key = try readVarint()
        return Field(number: Int(key >> 3), wireType: Int(key & 0x7))
    }

    mutating func readVarint() throws -> UInt64 {
        var result: UInt64 = 0
        var shift: UInt64 = 0

        while shift < 64 {
            guard offset < bytes.count else {
                throw TRXSDKError.invalidNodeResponse("Truncated protobuf varint")
            }

            let byte = bytes[offset]
            offset += 1
            result |= UInt64(byte & 0x7f) << shift
            if byte & 0x80 == 0 {
                return result
            }
            shift += 7
        }

        throw TRXSDKError.invalidNodeResponse("Invalid protobuf varint")
    }

    mutating func readLengthDelimitedData() throws -> Data {
        let count = Int(try readVarint())
        guard count >= 0, offset + count <= bytes.count else {
            throw TRXSDKError.invalidNodeResponse("Truncated protobuf message")
        }

        let start = offset
        offset += count
        return Data(bytes[start..<offset])
    }

    mutating func skip(wireType: Int) throws {
        switch wireType {
        case 0:
            _ = try readVarint()
        case 1:
            try advance(byteCount: 8)
        case 2:
            _ = try readLengthDelimitedData()
        case 5:
            try advance(byteCount: 4)
        default:
            throw TRXSDKError.invalidNodeResponse("Unsupported protobuf wire type \(wireType)")
        }
    }

    private mutating func advance(byteCount: Int) throws {
        guard offset + byteCount <= bytes.count else {
            throw TRXSDKError.invalidNodeResponse("Truncated protobuf field")
        }
        offset += byteCount
    }
}
