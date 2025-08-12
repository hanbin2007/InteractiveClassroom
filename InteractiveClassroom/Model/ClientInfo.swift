import Foundation
import SwiftData

/// Stores information about a connected client.
@Model
final class ClientInfo {
    /// Device name reported by `MCPeerID`.
    var deviceName: String
    /// User provided nickname.
    var nickname: String
    /// Chosen role (teacher or student).
    var role: String
    /// IP address if available.
    var ipAddress: String?
    /// Last time the connection succeeded.
    var lastConnected: Date
    /// Indicates whether the client is currently connected.
    var isConnected: Bool

    init(deviceName: String,
         nickname: String,
         role: String,
         ipAddress: String? = nil,
         lastConnected: Date = .now,
         isConnected: Bool = true) {
        self.deviceName = deviceName
        self.nickname = nickname
        self.role = role
        self.ipAddress = ipAddress
        self.lastConnected = lastConnected
        self.isConnected = isConnected
    }
}
