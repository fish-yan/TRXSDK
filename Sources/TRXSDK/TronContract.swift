import Foundation
import SwiftProtobuf

public struct TronContract {
    private let from: Address
    private let to: Address
    private let amount: Int64

    public init(from: Address, to: Address, amount: Int64) {
        self.from = from
        self.to = to
        self.amount = amount
    }

    public func contract() throws -> Protocol_Transaction.Contract {
        var contract = Protocol_Transaction.Contract()
        var transferContract = Protocol_TransferContract()
        transferContract.ownerAddress = from.data
        transferContract.toAddress = to.data
        transferContract.amount = amount
        contract.type = .transferContract
        contract.parameter = try Google_Protobuf_Any(message: transferContract)
        return contract
    }
}
