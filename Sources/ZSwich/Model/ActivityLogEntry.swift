import Foundation

struct ActivityLogEntry: Identifiable, Sendable {
    enum Kind: Sendable {
        case info
        case success
        case error
    }

    let id = UUID()
    let date = Date.now
    let message: String
    let kind: Kind
}
