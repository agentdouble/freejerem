import Carbon.HIToolbox

@MainActor
final class GlobalHotKeyManager {
    private enum HotKeyID: UInt32 {
        case mouse = 1
        case text = 2
        case stopAll = 3
        case mixed = 4
    }

    private let coordinator: AutomationCoordinator
    private var references: [EventHotKeyRef?] = []
    private var eventHandler: EventHandlerRef?

    init(coordinator: AutomationCoordinator) {
        self.coordinator = coordinator
    }

    func unregisterAll() {
        for reference in references {
            if let reference { UnregisterEventHotKey(reference) }
        }
        if let eventHandler { RemoveEventHandler(eventHandler) }
        references.removeAll()
        eventHandler = nil
    }

    func registerDefaultHotKeys() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            Self.eventCallback,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        register(id: .mouse, keyCode: UInt32(kVK_ANSI_M))
        register(id: .text, keyCode: UInt32(kVK_ANSI_T))
        register(id: .mixed, keyCode: UInt32(kVK_ANSI_A))
        register(id: .stopAll, keyCode: UInt32(kVK_ANSI_S))
    }

    private func register(id: HotKeyID, keyCode: UInt32) {
        var reference: EventHotKeyRef?
        let identifier = EventHotKeyID(signature: Self.signature, id: id.rawValue)
        RegisterEventHotKey(
            keyCode,
            UInt32(cmdKey | optionKey),
            identifier,
            GetApplicationEventTarget(),
            0,
            &reference
        )
        references.append(reference)
    }

    private func handle(id: UInt32) {
        switch HotKeyID(rawValue: id) {
        case .mouse: coordinator.toggleMouse()
        case .text: coordinator.toggleText()
        case .mixed: coordinator.toggleMixed()
        case .stopAll: coordinator.stopAll()
        case nil: break
        }
    }

    private static let signature: OSType = 0x464A524D

    private static let eventCallback: EventHandlerUPP = { _, event, userData in
        guard let event, let userData else { return OSStatus(eventNotHandledErr) }
        var identifier = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &identifier
        )
        guard status == noErr, identifier.signature == signature else { return status }

        let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
        MainActor.assumeIsolated { manager.handle(id: identifier.id) }
        return noErr
    }
}
