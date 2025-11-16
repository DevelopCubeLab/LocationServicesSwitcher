import Foundation
import UserNotifications

class NotificationController {
    // 单例模式
    static let instance = NotificationController()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    /// 统一的通知标识（用于避免堆积同类通知 & 让 willPresent/didReceive 能识别）
    static let turnOnIdentifier = "com.developlab.LocationServicesSwitcher.notification.turnOn"
    static let turnOffIdentifier = "com.developlab.LocationServicesSwitcher.notification.turnOff"
    
    static let notificationCategoryID = "com.developlab.LocationServicesSwitcher.notification.disable.group"
    static let notificationActionID = "com.developlab.LocationServicesSwitcher.notification.disable"

    /// 统一处理通知权限检查与请求
    /// - Note:
    ///   - 若当前为 `.notDetermined` 则会触发系统授权弹窗，并在用户选择后回调 `.authorized` 或 `.denied`
    ///   - 其它情况直接返回当前的 `authorizationStatus`
    func ensureAuthorization(completion: @escaping (UNAuthorizationStatus) -> Void) {
        center.getNotificationSettings { [weak self] settings in
            guard let _ = self else { return }
            completion(settings.authorizationStatus)
        }
    }

    // MARK: - 权限
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        if #available(iOS 15.0, *) {
            center.requestAuthorization(options: [.alert, .sound, .badge, .timeSensitive]) { granted, _ in
                completion(granted)
            }
        } else {
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                completion(granted)
            }
        }
    }

    func getSettings(_ completion: @escaping (UNNotificationSettings) -> Void) {
        center.getNotificationSettings { settings in completion(settings) }
    }
    
    func setupNotificationCategories() {
        // “关闭通知”
        let disableAction = UNNotificationAction(
            identifier: Self.notificationActionID,
            title: NSLocalizedString("DisableNotifications", comment: "禁用通知"),
            options: [.foreground]
        )

        let category = UNNotificationCategory(
            identifier: Self.notificationCategoryID,
            actions: [disableAction],   // 长按菜单里只有它
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([category])
    }

    // MARK: - 发送：快捷入口（参数化）
    /// - Parameters:
    ///   - title: 通知标题（例如："快速打开 App"）
    ///   - preferTimeSensitive: 若系统允许则使用时效性
    ///   - silentIfNotTimeSensitive: 当不使用时效性时是否静默（不出声）
    ///   - identifier: 自定义标识；不传则使用 `identifierOpenApp`
    func postShortcutNow(title: String,
                         preferTimeSensitive: Bool = true,
                         silentIfNotTimeSensitive: Bool = true,
                         identifier: String? = nil) {
        guard SettingsUtils.instance.getEnableNotifications() else { return }
        let id = identifier ?? NotificationController.turnOnIdentifier

        if #available(iOS 15.0, *) {
            getSettings { [weak self] settings in
                guard let self = self else { return }
                let content = UNMutableNotificationContent()
                content.title = title
                content.categoryIdentifier = NotificationController.notificationCategoryID // 加上关闭按钮的分类
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    if preferTimeSensitive && settings.timeSensitiveSetting == .enabled {
                        content.interruptionLevel = .timeSensitive
                        // 不强制声音，由调用者通过 silentIfNotTimeSensitive 控制降级时是否静默
                    } else if silentIfNotTimeSensitive {
                        content.sound = nil
                    }
                default:
                    return // 未授权
                }

                self.center.removeDeliveredNotifications(withIdentifiers: [id])
                let req = UNNotificationRequest(identifier: id, content: content, trigger: nil)
                self.center.add(req, withCompletionHandler: nil)
            }
        } else {
            // iOS < 15：无时效性，按静默普通通知发送
            let content = UNMutableNotificationContent()
            content.title = title
            content.categoryIdentifier = NotificationController.notificationCategoryID // 加上关闭按钮的分类
            if silentIfNotTimeSensitive {
                content.sound = nil
            }
            center.removeDeliveredNotifications(withIdentifiers: [id])
            let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
            center.add(request, withCompletionHandler: nil)
        }
    }

    // MARK: - 发送：打开/关闭定位服务专用入口
    func postNotification(title: String,
                                messageId: String,
                                preferTimeSensitive: Bool = true,
                                silentIfNotTimeSensitive: Bool = true) {
        postShortcutNow(title: title,
                        preferTimeSensitive: preferTimeSensitive,
                        silentIfNotTimeSensitive: silentIfNotTimeSensitive,
                        identifier: messageId)
    }


    // MARK: - 发送：回补静默（仅列表，不弹横幅由 willPresent 控制）
    func postFollowUpSilent(title: String, identifier: String? = nil) {
        guard SettingsUtils.instance.getEnableNotifications() else { return }
        let id = identifier ?? NotificationController.turnOnIdentifier

        if #available(iOS 15.0, *) {
            getSettings { [weak self] settings in
                guard let self = self else { return }
                let content = UNMutableNotificationContent()
                content.title = title
                content.categoryIdentifier = NotificationController.notificationCategoryID // 加上关闭按钮的分类
                content.sound = nil
                if settings.timeSensitiveSetting == .enabled {
                    content.interruptionLevel = .timeSensitive
                }
                let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
                self.center.add(request, withCompletionHandler: nil)
            }
        } else {
            let content = UNMutableNotificationContent()
            content.title = title
            content.categoryIdentifier = NotificationController.notificationCategoryID // 加上关闭按钮的分类
            content.sound = nil
            let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
            center.add(request, withCompletionHandler: nil)
        }
    }

    // MARK: - 前台展示策略（供 AppDelegate 复用）
    /// 回补通知只进列表，其余正常（横幅+列表）
    func presentationOptions(for notification: UNNotification) -> UNNotificationPresentationOptions {
        if #available(iOS 14.0, *) {
            if notification.request.identifier == NotificationController.turnOnIdentifier {
                return [.list]
            } else {
                return [.banner, .list]
            }
        } else {
            return [.alert]
        }
    }
    
    // 清除全部通知
    func clearAllNotifications() {
        center.removeAllPendingNotificationRequests()   // 移除所有未触发的
        center.removeAllDeliveredNotifications()        // 移除通知中心已显示的
    }
    
}
