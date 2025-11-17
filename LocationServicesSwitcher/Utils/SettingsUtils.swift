import Foundation
import UIKit

class SettingsUtils {
    
    // 单例实例
    static let instance = SettingsUtils()
    
    // 私有的 PlistManagerUtils 实例，用于管理特定的 plist 文件
    private let plistManager: PlistManagerUtils
    
    private init() {
        // 初始化
        self.plistManager = PlistManagerUtils.instance(for: "Settings")
    }
    
    static let disableAutoSwitchShortcutItemID = "com.developlab.LocationServicesSwitcher.quickAction.cancel"
    
    private func setDefaultSettings() {
        
        if self.plistManager.isPlistExist() {
            return
        }
        
    }
    
    // 检查UnSandbox权限的方法
    static func checkUnSandboxPermission() -> Bool {
        let path = "/var/mobile/Library/Preferences"
        let writeable = access(path, W_OK) == 0
        return writeable
    }
    
    /// 获取启动App时自动切换
    func getExitAfterSwitching() -> Bool {
        return plistManager.getBool(key: "ExitAfterSwitching", defaultValue: false)
    }
    
    func setExitAfterSwitching(enable: Bool) {
        plistManager.setBool(key: "ExitAfterSwitching", value: enable)
        plistManager.apply()
    }
    
    /// 获取是否切换后退出应用程序
    func getAutomaticallySwitchWhenStartingApp() -> Bool {
        return plistManager.getBool(key: "AutomaticallySwitchWhenStartingApp", defaultValue: false)
    }
    
    func setAutomaticallySwitchWhenStartingApp(enable: Bool) {
        plistManager.setBool(key: "AutomaticallySwitchWhenStartingApp", value: enable)
        plistManager.apply()
    }
    
    /// 获取是否开启通知
    func getEnableNotifications() -> Bool {
        return plistManager.getBool(key: "EnableNotifications", defaultValue: false)
    }
    
    func setEnableNotifications(enable: Bool) {
        plistManager.setBool(key: "EnableNotifications", value: enable)
        plistManager.apply()
    }
    
    /// 获取是否由Widget打开app
    func getLaunchingFromWidget() -> Bool {
        return plistManager.getBool(key: "LaunchingFromWidget", defaultValue: false)
    }
    
    func setLaunchingFromWidget(enable: Bool) {
        plistManager.setBool(key: "LaunchingFromWidget", value: enable)
        plistManager.apply()
    }
    
    // 配置桌面快捷方式
    func setShortcutItem(application: UIApplication, enable: Bool) {
        if enable {
            application.shortcutItems = [
                UIApplicationShortcutItem(
                    type: SettingsUtils.disableAutoSwitchShortcutItemID,
                    localizedTitle: NSLocalizedString("DisableAutoSwitch", comment: ""),
                    localizedSubtitle: nil,
                    icon: UIApplicationShortcutIcon(systemImageName: "xmark.circle"),
                    userInfo: nil
                )
            ]
        } else {
            application.shortcutItems = []
        }
    }
}
