import AppIntents

@available(iOS 16, *)
struct getLocationServicesIntent: AppIntent {
    static var title: LocalizedStringResource = "LocationServicesStatus"
    static var description = IntentDescription("LocationServicesStatusDescription")

    static var resultType: Bool.Type { Bool.self }
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let status = CoreLocationController.instance.locationServicesEnabled
        return .result(value: status)
    }
}

@available(iOS 16, *)
struct turnOnLocationServicesIntent: AppIntent {
    static var title: LocalizedStringResource = "TurnOnLocationServicesAppIntentTitle"
    static var description = IntentDescription("TurnOnLocationServicesDescription")

    static var resultType: Bool.Type { Bool.self }
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let result = CoreLocationController.instance.performSwitch(
            enable: true,
            sendNotifications: SettingsUtils.instance.getEnableNotifications(),
            window: nil
        )
        return .result(value: result)
    }
}

@available(iOS 16, *)
struct turnOffLocationServicesIntent: AppIntent {
    static var title: LocalizedStringResource = "TurnOffLocationServicesAppIntentTitle"
    static var description = IntentDescription("TurnOffLocationServicesDescription")

    static var resultType: Bool.Type { Bool.self }
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let result = CoreLocationController.instance.performSwitch(
            enable: false,
            sendNotifications: SettingsUtils.instance.getEnableNotifications(),
            window: nil
        )
        return .result(value: result)
    }
}


@available(iOS 16, *)
struct toggleLocationServicesIntent: AppIntent {
    static var title: LocalizedStringResource = "ToggleLocationServices"
    static var description = IntentDescription("ToggleLocationServicesDescription")

    static var resultType: Bool.Type { Bool.self }
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let result = CoreLocationController.instance.performSwitch(
            enable: !CoreLocationController.instance.locationServicesEnabled,
            sendNotifications: SettingsUtils.instance.getEnableNotifications(),
            window: nil
        )
        return .result(value: result)
    }
}
