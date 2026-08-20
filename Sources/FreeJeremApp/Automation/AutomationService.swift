import CoreGraphics
import Foundation

@MainActor
protocol AutomationService: AnyObject {
    var isRunning: Bool { get }
    func start() throws
    func stop()
}

enum AutomationError: LocalizedError {
    case mouseEventUnavailable
    case mouseMovementFailed(CGError)
    case cannotCreateTextFile(URL, Error)
    case cannotWriteTextFile(URL, Error)

    var errorDescription: String? {
        switch self {
        case .mouseEventUnavailable:
            return "FreeJerem ne peut pas lire la position de la souris."
        case .mouseMovementFailed(let error):
            return "Le déplacement de la souris a échoué (code \(error.rawValue))."
        case .cannotCreateTextFile(let url, let error):
            return "Impossible de créer \(url.lastPathComponent) : \(error.localizedDescription)"
        case .cannotWriteTextFile(let url, let error):
            return "Impossible d’écrire dans \(url.lastPathComponent) : \(error.localizedDescription)"
        }
    }
}
