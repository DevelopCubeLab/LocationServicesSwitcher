import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 设置通知代理
        UNUserNotificationCenter.current().delegate = self
        // 注册通知分类
        NotificationController.instance.setupNotificationCategories()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = UINavigationController(rootViewController: MainViewController())
        window!.makeKeyAndVisible()
        return true
    }
    
    // 处理点击锁屏Widget的方法
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        let type = userActivity.activityType

        if type == "LocationSwitcherOn" { // 打开定位服务
            if !CoreLocationController.instance.setLocationServicesEnabled(true) {
                if let root = window?.rootViewController {
                    UIUtils.showAlert(message: NSLocalizedString("SwitchLocationServiceFailed", comment: ""), in: root)
                }
            } else {
                UIUtils.exitApplicationAfterSwitching()
            }
        }

        if type == "LocationSwitcherOff" { // 关闭定位服务
            if !CoreLocationController.instance.setLocationServicesEnabled(false) {
                if let root = window?.rootViewController {
                    UIUtils.showAlert(message: NSLocalizedString("SwitchLocationServiceFailed", comment: ""), in: root)
                }
            } else {
                UIUtils.exitApplicationAfterSwitching()
            }
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
                if CoreLocationController.instance.setLocationServicesEnabled(true) {
                    // 再发送一条通知，这样就不会导致通知消失了
                    NotificationController.instance.postFollowUpSilent(title: NSLocalizedString("TurnOffLocationServices", comment: ""), identifier: NotificationController.turnOffIdentifier)
                    // 判断是否退出程序
                    UIUtils.exitApplicationAfterSwitching()
                } else {
                    if let root = window?.rootViewController {
                        UIUtils.showAlert(message: NSLocalizedString("SwitchLocationServiceFailed", comment: ""), in: root)
                    }
                }
            }

            if id == NotificationController.turnOffIdentifier {
                // 用户点击“关闭定位服务”的通知
                if CoreLocationController.instance.setLocationServicesEnabled(false) {
                    // 再发送一条通知，这样就不会导致通知消失了
                    NotificationController.instance.postFollowUpSilent(title: NSLocalizedString("TurnOnLocationServices", comment: ""), identifier: NotificationController.turnOnIdentifier)
                    // 判断是否退出程序
                    UIUtils.exitApplicationAfterSwitching()
                } else {
                    if let root = window?.rootViewController {
                        UIUtils.showAlert(message: NSLocalizedString("SwitchLocationServiceFailed", comment: ""), in: root)
                    }
                }
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
