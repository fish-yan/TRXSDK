import Foundation

public enum TRXSDKError: Error, Equatable, LocalizedError {
    case invalidHexString(String)
    case invalidPrivateKey
    case invalidPublicKey
    case invalidAddress(String)
    case invalidAmount(String)
    case amountOverflow(String)
    case invalidSignature
    case invalidNodeURL(String)
    case invalidNodeResponse(String)
    case nodeHTTPStatus(Int)
    case missingClient
    case unsupportedTransactionContract(String)
    case nodeRejected(code: Int, reason: String)

    public var errorDescription: String? {
        switch self {
        case .invalidHexString(let value):
            return "Invalid hex string: \(value)"
        case .invalidPrivateKey:
            return "Invalid secp256k1 private key"
        case .invalidPublicKey:
            return "Invalid secp256k1 public key"
        case .invalidAddress(let value):
            return "Invalid TRON address: \(value)"
        case .invalidAmount(let value):
            return "Invalid amount: \(value)"
        case .amountOverflow(let value):
            return "Amount is too large: \(value)"
        case .invalidSignature:
            return "Invalid secp256k1 signature"
        case .invalidNodeURL(let value):
            return "Invalid TRON node URL: \(value)"
        case .invalidNodeResponse(let reason):
            return "Invalid TRON node response: \(reason)"
        case .nodeHTTPStatus(let statusCode):
            return "TRON node returned HTTP status \(statusCode)"
        case .missingClient:
            return "A TronNodeClient is required for network calls"
        case .unsupportedTransactionContract(let type):
            return "Unsupported transaction contract: \(type)"
        case .nodeRejected(_, let reason):
            return reason
        }
    }
}
