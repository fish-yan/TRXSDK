import Foundation

public struct TRONAccountResource: Equatable, Sendable {
    public var availableBalance: String
    public var frozenBalance: String
    public var totalBalance: String

    public var frozenNet: String
    public var frozenEnergy: String
    public var delegatedFrozenNet: String
    public var delegatedEnergy: String

    public var expireTimeNet: Int64
    public var expireTimeEnergy: Int64
    public var canUnfreezeNet: Bool
    public var canUnfreezeEnergy: Bool

    public var freeNetUsed: String
    public var freeNetLimit: String
    public var netUsed: String
    public var netLimit: String
    public var totalNetLimit: String
    public var totalNetWeight: String

    public var energyUsed: String
    public var energyLimit: String
    public var totalEnergyLimit: String
    public var totalEnergyWeight: String

    public var storageUsed: String
    public var storageLimit: String

    public init(
        availableBalance: String = "",
        frozenBalance: String = "",
        totalBalance: String = "",
        frozenNet: String = "",
        frozenEnergy: String = "",
        delegatedFrozenNet: String = "",
        delegatedEnergy: String = "",
        expireTimeNet: Int64 = 0,
        expireTimeEnergy: Int64 = 0,
        canUnfreezeNet: Bool = false,
        canUnfreezeEnergy: Bool = false,
        freeNetUsed: String = "",
        freeNetLimit: String = "",
        netUsed: String = "",
        netLimit: String = "",
        totalNetLimit: String = "",
        totalNetWeight: String = "",
        energyUsed: String = "",
        energyLimit: String = "",
        totalEnergyLimit: String = "",
        totalEnergyWeight: String = "",
        storageUsed: String = "",
        storageLimit: String = ""
    ) {
        self.availableBalance = availableBalance
        self.frozenBalance = frozenBalance
        self.totalBalance = totalBalance
        self.frozenNet = frozenNet
        self.frozenEnergy = frozenEnergy
        self.delegatedFrozenNet = delegatedFrozenNet
        self.delegatedEnergy = delegatedEnergy
        self.expireTimeNet = expireTimeNet
        self.expireTimeEnergy = expireTimeEnergy
        self.canUnfreezeNet = canUnfreezeNet
        self.canUnfreezeEnergy = canUnfreezeEnergy
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
