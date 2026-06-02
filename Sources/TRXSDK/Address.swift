import Foundation

public protocol Address: CustomStringConvertible {
    static func isValid(data: Data) -> Bool
    static func isValid(string: String) -> Bool

    var data: Data { get }

    init?(string: String)
    init?(data: Data)
}
