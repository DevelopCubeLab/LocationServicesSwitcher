import Foundation

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
}
