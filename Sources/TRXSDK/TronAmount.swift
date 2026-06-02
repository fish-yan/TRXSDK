import Foundation

public enum TronAmount {
    public static func trxFromSun(_ sun: String) -> String {
        decimalString(sun, scale: 6)
    }

    public static func sunFromTRX(_ trx: String) throws -> String {
        try scaledIntegerString(trx, decimals: 6)
    }

    public static func scaledInt64(_ amount: String, decimals: Int) throws -> Int64 {
        let value = try scaledIntegerString(amount, decimals: decimals)
        guard let intValue = Int64(value) else {
            throw TRXSDKError.amountOverflow(amount)
        }
        return intValue
    }

    public static func uint256Data(_ amount: String, decimals: Int) throws -> Data {
        let value = try scaledIntegerString(amount, decimals: decimals)
        return try uint256Data(decimalString: value)
    }

    public static func uint256Data(decimalString: String) throws -> Data {
        let normalized = normalizeInteger(decimalString)
        guard normalized.allSatisfy({ $0 >= "0" && $0 <= "9" }) else {
            throw TRXSDKError.invalidAmount(decimalString)
        }

        var bytes = [UInt8](repeating: 0, count: 32)
        for digitCharacter in normalized.utf8 {
            let digit = Int(digitCharacter - 48)
            var carry = digit
            for index in stride(from: 31, through: 0, by: -1) {
                let value = Int(bytes[index]) * 10 + carry
                bytes[index] = UInt8(value & 0xff)
                carry = value >> 8
            }
            guard carry == 0 else {
                throw TRXSDKError.amountOverflow(decimalString)
            }
        }
        return Data(bytes)
    }

    public static func scaledIntegerString(_ amount: String, decimals: Int) throws -> String {
        let trimmed = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard decimals >= 0, !trimmed.isEmpty, !trimmed.hasPrefix("-") else {
            throw TRXSDKError.invalidAmount(amount)
        }

        let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2 else {
            throw TRXSDKError.invalidAmount(amount)
        }

        let whole = String(parts[0])
        let fractional = parts.count == 2 ? String(parts[1]) : ""
        guard whole.allSatisfy(\.isNumber), fractional.allSatisfy(\.isNumber) else {
            throw TRXSDKError.invalidAmount(amount)
        }
        guard fractional.count <= decimals else {
            let overflow = fractional.dropFirst(decimals)
            guard overflow.allSatisfy({ $0 == "0" }) else {
                throw TRXSDKError.invalidAmount(amount)
            }
            return normalizeInteger(whole + fractional.prefix(decimals))
        }

        let paddedFractional = fractional + String(repeating: "0", count: decimals - fractional.count)
        return normalizeInteger(whole + paddedFractional)
    }

    private static func decimalString(_ value: String, scale: Int) -> String {
        let normalized = normalizeInteger(value)
        guard scale > 0 else {
            return normalized
        }

        let padded = String(repeating: "0", count: max(0, scale + 1 - normalized.count)) + normalized
        let splitIndex = padded.index(padded.endIndex, offsetBy: -scale)
        let whole = String(padded[..<splitIndex])
        let fraction = padded[splitIndex...].reversed().drop(while: { $0 == "0" }).reversed()
        if fraction.isEmpty {
            return whole
        }
        return "\(whole).\(String(fraction))"
    }

    private static func normalizeInteger(_ value: String) -> String {
        let trimmed = value.drop(while: { $0 == "0" })
        return trimmed.isEmpty ? "0" : String(trimmed)
    }
}
