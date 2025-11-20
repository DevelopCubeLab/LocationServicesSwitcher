import Foundation
import UIKit

class CoreLocationController {
    
    // 单例实例
    static let instance = CoreLocationController()
    
    var locationServicesEnabled: Bool = CLLocationManager.locationServicesEnabled()
    
    private init() { // 私有构造方法
        //
    }
    
    /// 刷新状态
    func updateLocationServicesStatus() {
        locationServicesEnabled = CLLocationManager.locationServicesEnabled()
    }
    
    /// 设置定位服务状态
    func setLocationServicesEnabled(_ enable: Bool) -> Bool {
        if !SettingsUtils.checkUnSandboxPermission() { // 判断沙盒权限
            return false
        }
        let before = CLLocationManager.locationServicesEnabled()
        // 如果本来就是该状态 → 不需要切换 → 判定为成功
        if before == enable {
            return true
        }
        // 执行切换
        CLLocationManager.setLocationServicesEnabled(enable)
        let after = CLLocationManager.locationServicesEnabled()
        // 成功切换
        if after == enable {
            return true
        }
        // 切换失败
        return false
    }
    
    /// 执行完整的定位切换逻辑，包含通知处理与退出
    func performSwitch(enable: Bool, sendNotifications: Bool, window: UIWindow?) -> Bool {
        // 先尝试切换
        if !setLocationServicesEnabled(enable) {
            if let root = window?.rootViewController {
                UIUtils.showAlert(message: NSLocalizedString("SwitchLocationServiceFailed", comment: ""), in: root)
                return false
            }
            return true
        }

        // 处理通知
        if sendNotifications {
            NotificationController.instance.clearAllNotifications()
            if enable {
                NotificationController.instance.postFollowUpSilent(
                    title: NSLocalizedString("TurnOffLocationServices", comment: ""),
                    identifier: NotificationController.turnOffIdentifier
                )
            } else {
                NotificationController.instance.postFollowUpSilent(
                    title: NSLocalizedString("TurnOnLocationServices", comment: ""),
                    identifier: NotificationController.turnOnIdentifier
                )
            }
        }
        // 自动退出
        UIUtils.exitApplicationAfterSwitching()
        return true
    }
}
