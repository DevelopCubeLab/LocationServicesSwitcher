import UIKit
import CoreLocation

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    static let versionCode = "1.1"
    
    private var tableView = UITableView()

    private var tableCellList = [
        [NSLocalizedString("LocationServicesStatus", comment: "定位服务状态")],
        [NSLocalizedString("TurnOnLocationServices", comment: "开启定位服务")],
        [NSLocalizedString("TurnOffLocationServices", comment: "关闭定位服务")],
        [NSLocalizedString("AutomaticallySwitchWhenStartingTheApp", comment: "启动App时自动切换"), NSLocalizedString("ExitAfterSwitching", comment: "切换后退出应用程序")],
        [],
        [NSLocalizedString("Version", comment: ""), "GitHub"]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("CFBundleDisplayName", comment: "定位开关")
        
        // 判断用户是否开启通知权限
        updateNotificationsCell()
        
        // iOS 15 之后的版本使用新的UITableView样式
        if #available(iOS 15.0, *) {
            tableView = UITableView(frame: .zero, style: .insetGrouped)
        } else {
            tableView = UITableView(frame: .zero, style: .grouped)
        }

        // 设置表格视图的代理和数据源
        tableView.delegate = self
        tableView.dataSource = self
        
        // 注册表格单元格
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        // 将表格视图添加到主视图
        view.addSubview(tableView)

        // 设置表格视图的布局
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 注册通知，当app回到前台的时候刷新定位状态
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    // App从后台回来时的回调
    @objc private func appDidBecomeActive() {
        updateLocationStatus()
        updateNotificationsCell()
    }
    
    private func updateLocationStatus() {
        CoreLocationController.instance.updateLocationServicesStatus()
        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
    }
    
    // MARK: - 设置总分组数量
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableCellList.count
    }
    
    // MARK: - 设置每个分组的Cell数量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableCellList[section].count
    }
    
    // MARK: - 设置每个分组的顶部标题
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 3 {
            return NSLocalizedString("Options", comment: "选项")
        } else if section == 4 {
            return NSLocalizedString("Notifications", comment: "通知")
        } else if section == 5 {
            return NSLocalizedString("About", comment: "关于")
        }
        return nil
    }
    
    // MARK: - 设置每个分组的底部标题 可以为分组设置尾部文本，如果没有尾部可以返回 nil
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 4 {
            return NSLocalizedString("NotificationsFooterMessage", comment: "")
        }
        return nil
    }
    
    // MARK: - 构造每个Cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        
        cell.textLabel?.text = tableCellList[indexPath.section][indexPath.row]
        cell.textLabel?.numberOfLines = 0 // 允许换行
        
        if indexPath.section == 0 {
            cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
            cell.textLabel?.text = tableCellList[indexPath.section][indexPath.row]
            cell.detailTextLabel?.text = CoreLocationController.instance.locationServicesEnabled ? NSLocalizedString("Enabled", comment: "已开启") : NSLocalizedString("Disabled", comment: "已关闭")
        } else if indexPath.section == 1 {
            cell.textLabel?.textColor = .systemBlue // 文本设置成蓝色
        } else if indexPath.section == 2 {
            cell.textLabel?.textColor = .systemRed // 文本设置成红色
        } else if indexPath.section == 3 { // 选项
            let switchView = UISwitch(frame: .zero)
            switchView.tag = indexPath.row // 设置识别id
            if indexPath.row == 0 { // 启动App时自动切换
                switchView.isOn = SettingsUtils.instance.getAutomaticallySwitchWhenStartingApp() // 从配置文件中获取状态
            } else if indexPath.row == 1 { // 切换后退出应用程序
                switchView.isOn = SettingsUtils.instance.getExitAfterSwitching() // 从配置文件中获取状态
            }
            // 开光状态改变的回调
            switchView.addAction(UIAction { [weak self] action in
                self?.onSwitchChanged(action.sender as! UISwitch)
            }, for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
        } else if indexPath.section == 4 {
            if indexPath.row == 0 {
                let switchView = UISwitch(frame: .zero)
                switchView.tag = 2 // 设置识别id
                switchView.isOn = SettingsUtils.instance.getEnableNotifications() // 从配置文件中获取状态
                // 开光状态改变的回调
                switchView.addAction(UIAction { [weak self] action in
                    self?.onSwitchChanged(action.sender as! UISwitch)
                }, for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
            } else {
                cell.textLabel?.textColor = .systemBlue // 文本设置成蓝色
                cell.accessoryType = .disclosureIndicator
            }
        } else if indexPath.section == 5 { // 关于
            if indexPath.row == 0 {
                cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
                cell.textLabel?.text = tableCellList[indexPath.section][indexPath.row]
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? NSLocalizedString("Unknown", comment: "未知")
                if version != MainViewController.versionCode { // 判断版本号是不是有人篡改
                    cell.detailTextLabel?.text = MainViewController.versionCode
                } else {
                    cell.detailTextLabel?.text = version
                }
                cell.selectionStyle = .none
                cell.accessoryType = .none
            } else {
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default // 启用选中效果
            }
        }
        
        return cell
        
    }
    
    // MARK: - Cell的点击事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 || indexPath.section == 2 {
            if !(CoreLocationController.instance.setLocationServicesEnabled(indexPath.section == 1)) {
                // 显示错误弹窗
                UIUtils.showAlert(message: NSLocalizedString("SwitchLocationServiceFailed", comment: "切换失败提示"), in: self)
            } else {
                // 静默发送一个相反的通知
                sendMuteNotification(enableLocationServer: indexPath.section == 2)
                UIUtils.exitApplicationAfterSwitching()
            }
            // 刷新开关状态
            updateLocationStatus()
        } else if indexPath.section == 4 { // MARK: TODO 这里处理的太不优雅了
            if indexPath.row == 1 {
                if tableCellList[4].count == 3 {
                    // 点击发送通知
                    onClickSendNotification()
                } else {
                    // 点击跳转通知设置
                    onClickToNotificationSettings()
                }
            } else if indexPath.row == 2 {
                // 点击跳转通知设置
                onClickToNotificationSettings()
            }
        } else if indexPath.section == 5 {
            if indexPath.row == 1 {
                if let url = URL(string: "https://github.com/DevelopCubeLab/LocationServicesSwitcher") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
        
    }
    
    /// 当开关更改的时候的方法
    private func onSwitchChanged(_ sender: UISwitch) {
        if sender.tag == 0 {
            SettingsUtils.instance.setAutomaticallySwitchWhenStartingApp(enable: sender.isOn)
            if sender.isOn && SettingsUtils.instance.getExitAfterSwitching() {
                // 显示提示
                UIUtils.showAlert(message: String.localizedStringWithFormat(NSLocalizedString("AutoSwitchAndExitHintMessage", comment: "同时打开自动操作和自动退出程序的提示"), NSLocalizedString("AutomaticallySwitchWhenStartingTheApp", comment: ""),NSLocalizedString("ExitAfterSwitching", comment: ""), NSLocalizedString("DisableAutoSwitch", comment: ""), NSLocalizedString("AutomaticallySwitchWhenStartingTheApp", comment: "")), in: self)
                // 配置桌面快捷方式
                SettingsUtils.instance.setShortcutItem(application: UIApplication.shared, enable: true)
            } else {
                // 配置桌面快捷方式
                SettingsUtils.instance.setShortcutItem(application: UIApplication.shared, enable: false)
            }
        } else if sender.tag == 1 {
            SettingsUtils.instance.setExitAfterSwitching(enable: sender.isOn)
            if sender.isOn && SettingsUtils.instance.getAutomaticallySwitchWhenStartingApp() {
                // 显示提示
                UIUtils.showAlert(message: String.localizedStringWithFormat(NSLocalizedString("AutoSwitchAndExitHintMessage", comment: "同时打开自动操作和自动退出程序的提示"), NSLocalizedString("AutomaticallySwitchWhenStartingTheApp", comment: ""),NSLocalizedString("ExitAfterSwitching", comment: ""), NSLocalizedString("DisableAutoSwitch", comment: ""), NSLocalizedString("AutomaticallySwitchWhenStartingTheApp", comment: "")), in: self)
                // 配置桌面快捷方式
                SettingsUtils.instance.setShortcutItem(application: UIApplication.shared, enable: true)
            } else {
                // 配置桌面快捷方式
                SettingsUtils.instance.setShortcutItem(application: UIApplication.shared, enable: false)
            }
        } else if sender.tag == 2 {
            if sender.isOn {
                // 判断通知权限
                NotificationController.instance.ensureAuthorization { status in
                    DispatchQueue.main.async {
                        switch status {
                        case .notDetermined: // 未授权
                            sender.setOn(false, animated: true)
                            // 授权
                            NotificationController.instance.requestAuthorization { granted in
                                DispatchQueue.main.async {
                                    if !granted { // 拒绝授权
                                        sender.setOn(false, animated: true)
                                        SettingsUtils.instance.setEnableNotifications(enable: false)
                                        UIUtils.showAlert(message: NSLocalizedString("NotificationsPermissionDenied", comment: "通知权限已拒绝"), in: self)
                                    } else {
                                        sender.setOn(true, animated: true)
                                        SettingsUtils.instance.setEnableNotifications(enable: true)
                                    }
                                    self.updateNotificationsCell()
                                }
                                
                            }
                            return
                        case .authorized, .provisional, .ephemeral: // 已授权
                            SettingsUtils.instance.setEnableNotifications(enable: true)
                            sender.setOn(true, animated: true)
                        case .denied: // 已拒绝
                            UIUtils.showAlert(
                                message: NSLocalizedString("NotificationsPermissionGoToSettings", comment: "通知权限已拒绝"),
                                in: self
                            )
                            sender.setOn(false, animated: true)
                        @unknown default:
                            sender.setOn(false, animated: true)
                        }
                        self.updateNotificationsCell()
                    }
                    
                }
            } else {
                // 用户关闭通知开关 → 仅更新设置
                SettingsUtils.instance.setEnableNotifications(enable: false)
                // 把所有通知删除
                NotificationController.instance.clearAllNotifications()
                updateNotificationsCell()
            }
            
        }
    }
    
    private func updateNotificationsCell() {
        // 第一次先清空
        tableCellList[4] = []
        tableCellList[4].append(NSLocalizedString("Enable", comment: ""))
        
        // 必须等待权限查询完才能更新 UI
        NotificationController.instance.ensureAuthorization { status in
            DispatchQueue.main.async {
                self.tableCellList[4] = []
                self.tableCellList[4].append(NSLocalizedString("Enable", comment: ""))
                switch status {
                case .authorized, .provisional, .ephemeral:
                    if SettingsUtils.instance.getEnableNotifications() {
                        // 用户开启开关 + 已授权
                        self.tableCellList[4].append(NSLocalizedString("SendNotification", comment: ""))
                        self.tableCellList[4].append(NSLocalizedString("GoToNotificationSettings", comment: ""))
                    }
                case .denied:
                    self.tableCellList[4].append(NSLocalizedString("GoToNotificationSettings", comment: ""))
                    if SettingsUtils.instance.getEnableNotifications() { // 如果用户去设置里给通知关闭了，那开关也给关闭
                        SettingsUtils.instance.setEnableNotifications(enable: false)
                    }
                case .notDetermined:
                    break
                @unknown default:
                    break
                }

                self.tableView.reloadSections([4], with: .none)
                // 刷新下自动切换开关，解决当用户点击快捷方式禁用后没有进行操作
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 3)], with: .none)
            }
        }
    }
    
    private func onClickSendNotification() {
        if CoreLocationController.instance.locationServicesEnabled {
            NotificationController.instance.postNotification(title: NSLocalizedString("TurnOffLocationServices", comment: "关闭定位服务"), messageId: NotificationController.turnOffIdentifier)
        } else {
            NotificationController.instance.postNotification(title: NSLocalizedString("TurnOnLocationServices", comment: "打开定位服务"), messageId: NotificationController.turnOnIdentifier)
        }
        UIUtils.showAlert(message: NSLocalizedString("SendNotificationMessage", comment: "发送通知成功"), in: self)
    }
    
    private func onClickToNotificationSettings() {
        // iOS 16+ 有官方通知设置跳转
        if #available(iOS 16.0, *) {
            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                return
            }
        }
        // iOS 15 以及更早靠 openSettingsURLString 跳转到 App 设置页
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func sendMuteNotification(enableLocationServer: Bool) {
        if SettingsUtils.instance.getEnableNotifications() {
            // 先清除通知
            NotificationController.instance.clearAllNotifications()
            if enableLocationServer { // 发送静默通知
                NotificationController.instance.postFollowUpSilent(title: NSLocalizedString("TurnOnLocationServices", comment: ""), identifier: NotificationController.turnOnIdentifier)
            } else {
                NotificationController.instance.postFollowUpSilent(title: NSLocalizedString("TurnOffLocationServices", comment: ""), identifier: NotificationController.turnOffIdentifier)
            }
        }
    }
    
    deinit { //销毁监听器
        NotificationCenter.default.removeObserver(self)
    }

}
