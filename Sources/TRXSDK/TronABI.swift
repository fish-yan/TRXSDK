import Foundation

public enum TronABI {
    public static func functionSelector(_ signature: String) -> Data {
        TRXCrypto.keccak256(Data(signature.utf8)).prefix(4)
    }

    public static func encodeTRC20Transfer(to address: String, amount: String, decimals: Int) throws -> Data {
        try encodeCall(
            signature: "transfer(address,uint256)",
            arguments: [
                addressWord(address),
                TronAmount.uint256Data(amount, decimals: decimals),
            ]
        )
    }

    public static func encodeTRC20Approve(spender address: String, amount: String, decimals: Int) throws -> Data {
        try encodeCall(
            signature: "approve(address,uint256)",
            arguments: [
                addressWord(address),
                TronAmount.uint256Data(amount, decimals: decimals),
            ]
        )
    }

    public static func encodeTRC20Allowance(owner: String, spender: String) throws -> Data {
        try encodeCall(
            signature: "allowance(address,address)",
            arguments: [
                addressWord(owner),
                addressWord(spender),
            ]
        )
    }

    public static func encodeTRC20BalanceOf(owner: String) throws -> Data {
        try encodeCall(
            signature: "balanceOf(address)",
            arguments: [addressWord(owner)]
        )
    }

    public static func encodeTRC721SafeTransferFrom(from: String, to: String, tokenID: String) throws -> Data {
        try encodeCall(
            signature: "safeTransferFrom(address,address,uint256)",
            arguments: [
                addressWord(from),
                addressWord(to),
                TronAmount.uint256Data(decimalString: tokenID),
            ]
        )
    }

    public static func encodeCall(signature: String, arguments: [Data]) throws -> Data {
        try arguments.reduce(functionSelector(signature)) { partialResult, argument in
            partialResult + (try argument.leftPadded(to: 32))
        }
    }

    public static func addressWord(_ address: String) throws -> Data {
        guard let addressData = TronAddress(string: address)?.data else {
            throw TRXSDKError.invalidAddress(address)
        }
        return Data(addressData.dropFirst())
    }
}
