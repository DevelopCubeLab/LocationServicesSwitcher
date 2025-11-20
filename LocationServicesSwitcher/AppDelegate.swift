import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    // 用于存储启动时的快捷方式
    var pendingQuickAction: UIApplicationShortcutItem?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 设置通知代理
        UNUserNotificationCenter.current().delegate = self
        // 注册通知分类
        NotificationController.instance.setupNotificationCategories()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = UINavigationController(rootViewController: MainViewController())
        window!.makeKeyAndVisible()
        
        // 检查是否通过快捷方式启动
        if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            pendingQuickAction = shortcutItem // 保存快捷方式
        }
        
        return true
    }
    
    // MARK: - App 激活后处理启动快捷方式
    func applicationDidBecomeActive(_ application: UIApplication) {
        if let item = pendingQuickAction {
            handleQuickAction(item)
            pendingQuickAction = nil
        }
        
        // 开启自动切换后，自动切换的逻辑
        if SettingsUtils.instance.getAutomaticallySwitchWhenStartingApp() {
            // 不能是Widget打开的app 不然会冲突
            CoreLocationController.instance.updateLocationServicesStatus()
            if !SettingsUtils.instance.getLaunchingFromWidget() {
                let target = !CoreLocationController.instance.locationServicesEnabled
                _ = CoreLocationController.instance.performSwitch(
                    enable: target,
                    sendNotifications: SettingsUtils.instance.getEnableNotifications(),
                    window: window
                )
            }
        }
    }

    // MARK: - 前台时的快捷方式处理
    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        handleQuickAction(shortcutItem)
        completionHandler(true)
    }

    // MARK: - 核心快捷方式处理逻辑（最简）
    private func handleQuickAction(_ item: UIApplicationShortcutItem) {
        if item.type == SettingsUtils.disableAutoSwitchShortcutItemID { // 禁用自动切换功能
            SettingsUtils.instance.setAutomaticallySwitchWhenStartingApp(enable: false)
            SettingsUtils.instance.setShortcutItem(application: UIApplication.shared, enable: false)
        }
    }
    
    // 处理点击锁屏Widget的方法
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        let type = userActivity.activityType
        
        if type == "LocationSwitcherOn" || type == "EnableLocationServicesIntent" { // 打开定位服务
            // 标记使用Widget启动
            SettingsUtils.instance.setLaunchingFromWidget(enable: true)
            return CoreLocationController.instance.performSwitch(
                enable: true,
                sendNotifications: SettingsUtils.instance.getEnableNotifications(),
                window: window
            )
        }

        if type == "LocationSwitcherOff" || type == "DisableLocationServicesIntent" { // 关闭定位服务
            // 标记使用Widget启动
            SettingsUtils.instance.setLaunchingFromWidget(enable: true)
            return CoreLocationController.instance.performSwitch(
                enable: false,
                sendNotifications: SettingsUtils.instance.getEnableNotifications(),
                window: window
            )
        }
        
        if type == "ToggleLocationServicesIntent" { // 切换定位服务状态
            // 标记使用Widget启动
            SettingsUtils.instance.setLaunchingFromWidget(enable: true)
            let target = !CoreLocationController.instance.locationServicesEnabled
            return CoreLocationController.instance.performSwitch(
                enable: target,
                sendNotifications: SettingsUtils.instance.getEnableNotifications(),
                window: window
            )
        }
        
        return true
    }
    
    // 前台也显示通知（横幅/列表），没有声音就不会响
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(NotificationController.instance.presentationOptions(for: notification))
    }

    // 点击通知的回调
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier { // 点击通知
            let id = response.notification.request.identifier

            if id == NotificationController.turnOnIdentifier {
                // 用户点击“开启定位服务”的通知
                _ = CoreLocationController.instance.performSwitch(
                    enable: true,
                    sendNotifications: true,
                    window: window
                )
            }

            if id == NotificationController.turnOffIdentifier {
                // 用户点击“关闭定位服务”的通知
                _ = CoreLocationController.instance.performSwitch(
                    enable: false,
                    sendNotifications: true,
                    window: window
                )
            }
        } else if response.actionIdentifier == NotificationController.notificationActionID { // 长按通知
            // 关闭通知
            SettingsUtils.instance.setEnableNotifications(enable: false)
            // 删除全部通知
            NotificationController.instance.clearAllNotifications()
        }
        
        completionHandler()
    }
}
