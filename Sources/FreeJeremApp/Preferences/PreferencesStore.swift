import Foundation

@MainActor
final class PreferencesStore {
    private enum Key {
        static let mouseInterval = "mouseInterval"
        static let mouseDistance = "mouseDistance"
        static let textInterval = "textInterval"
        static let textFilePath = "textFilePath"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.mouseInterval: 20.0,
            Key.mouseDistance: 12.0,
            Key.textInterval: 0.4
        ])
    }

    var mouseInterval: TimeInterval {
        get { defaults.double(forKey: Key.mouseInterval) }
        set { defaults.set(max(2, newValue), forKey: Key.mouseInterval) }
    }

    var mouseDistance: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.mouseDistance)) }
        set { defaults.set(max(1, newValue), forKey: Key.mouseDistance) }
    }

    var textInterval: TimeInterval {
        get { defaults.double(forKey: Key.textInterval) }
        set { defaults.set(max(0.1, newValue), forKey: Key.textInterval) }
    }

    var textFileURL: URL {
        get {
            if let path = defaults.string(forKey: Key.textFilePath), !path.isEmpty {
                return URL(fileURLWithPath: path)
            }
            return Self.defaultTextFileURL
        }
        set { defaults.set(newValue.path, forKey: Key.textFilePath) }
    }

    static var defaultTextFileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("FreeJerem", isDirectory: true)
            .appendingPathComponent("freejerem.txt")
    }
}
