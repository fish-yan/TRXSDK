import Foundation

public struct TronBlock {
    private let timestamp: Int64
    private let txTrieRoot: Data
    private let parentHash: Data
    private let number: Int64
    private let witnessAddress: Data
    private let version: Int32

    public init(
        timestamp: Int64,
        txTrieRoot: Data,
        parentHash: Data,
        number: Int64,
        witnessAddress: Data,
        version: Int32
    ) {
        self.timestamp = timestamp
        self.txTrieRoot = txTrieRoot
        self.parentHash = parentHash
        self.number = number
        self.witnessAddress = witnessAddress
        self.version = version
    }

    public var blockHeader: Protocol_BlockHeader {
        var blockHeader = Protocol_BlockHeader()
        var raw = Protocol_BlockHeader.raw()
        raw.timestamp = timestamp
        raw.txTrieRoot = txTrieRoot
        raw.parentHash = parentHash
        raw.number = number
        raw.witnessAddress = witnessAddress
        raw.version = version
        blockHeader.rawData = raw
        return blockHeader
    }
}
