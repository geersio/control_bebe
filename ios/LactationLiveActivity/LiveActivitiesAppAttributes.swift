import ActivityKit
import Foundation

// Contrato exigido por el plugin `live_activities` (no renombrar).
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    typealias LiveDeliveryData = ContentState

    /// Debe coincidir con el `ContentState` del plugin. `contentRevision` opcional: actividades antiguas sin clave decodifican `nil`.
    struct ContentState: Codable, Hashable {
        var appGroupId: String
        var contentRevision: Int64?
    }

    var id = UUID()
}

extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String {
        "\(id)_\(key)"
    }
}
