#!/usr/bin/env swift

import Cocoa
import Foundation
import ServiceManagement

// 用户默认键
let UserDefaultsFontSizeKey = "fontSize"
let UserDefaultsLaunchAtLoginKey = "launchAtLogin"

// 检查是否已有实例在运行
func isAlreadyRunning() -> Bool {
    let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "NetworkMonitor"
    let runningApps = NSWorkspace.shared.runningApplications
    return runningApps.contains { $0.bundleIdentifier == "com.networkmonitor.app" && $0.processIdentifier != getpid() }
}

// 设置窗口控制器
class SettingsWindowController: NSWindowController {
    var settingsVC: SettingsViewController?

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "设置"
        window.isReleasedWhenClosed = false
        window.center()

        let settingsVC = SettingsViewController()
        self.settingsVC = settingsVC
        window.contentViewController = settingsVC

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// 设置视图控制器
class SettingsViewController: NSViewController {
    private var launchAtLoginCheckbox: NSButton!
    private var fontSizeSlider: NSSlider!
    private var fontSizeLabel: NSTextField!
    private var fontSizePreviewLabel: NSTextField!

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 350, height: 220))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSettings()
    }

    private func setupUI() {
        // 开机自启动选项
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "开机自启动", target: self, action: #selector(launchAtLoginChanged))
        launchAtLoginCheckbox.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(launchAtLoginCheckbox)

        // 字体大小标题
        let fontSizeTitle = NSTextField(labelWithString: "字体大小:")
        fontSizeTitle.translatesAutoresizingMaskIntoConstraints = false
        fontSizeTitle.isEditable = false
        fontSizeTitle.isBordered = false
        fontSizeTitle.backgroundColor = .clear
        view.addSubview(fontSizeTitle)

        // 字体大小滑块
        fontSizeSlider = NSSlider(value: 11, minValue: 9, maxValue: 16, target: self, action: #selector(fontSizeChanged))
        fontSizeSlider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fontSizeSlider)

        // 字体大小标签
        fontSizeLabel = NSTextField(labelWithString: "11")
        fontSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        fontSizeLabel.isEditable = false
        fontSizeLabel.isBordered = false
        fontSizeLabel.backgroundColor = .clear
        view.addSubview(fontSizeLabel)

        // 预览标题
        let previewTitle = NSTextField(labelWithString: "预览:")
        previewTitle.translatesAutoresizingMaskIntoConstraints = false
        previewTitle.isEditable = false
        previewTitle.isBordered = false
        previewTitle.backgroundColor = .clear
        view.addSubview(previewTitle)

        // 预览标签
        fontSizePreviewLabel = NSTextField(labelWithString: "↑12.5K/s\n↓34.2K/s")
        fontSizePreviewLabel.translatesAutoresizingMaskIntoConstraints = false
        fontSizePreviewLabel.isEditable = false
        fontSizePreviewLabel.isBordered = true
        fontSizePreviewLabel.backgroundColor = NSColor.controlBackgroundColor
        fontSizePreviewLabel.alignment = .center
        view.addSubview(fontSizePreviewLabel)

        // 布局约束
        NSLayoutConstraint.activate([
            launchAtLoginCheckbox.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            launchAtLoginCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            fontSizeTitle.topAnchor.constraint(equalTo: launchAtLoginCheckbox.bottomAnchor, constant: 30),
            fontSizeTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            fontSizeSlider.centerYAnchor.constraint(equalTo: fontSizeTitle.centerYAnchor),
            fontSizeSlider.leadingAnchor.constraint(equalTo: fontSizeTitle.trailingAnchor, constant: 10),
            fontSizeSlider.widthAnchor.constraint(equalToConstant: 150),

            fontSizeLabel.centerYAnchor.constraint(equalTo: fontSizeTitle.centerYAnchor),
            fontSizeLabel.leadingAnchor.constraint(equalTo: fontSizeSlider.trailingAnchor, constant: 10),
            fontSizeLabel.widthAnchor.constraint(equalToConstant: 30),

            previewTitle.topAnchor.constraint(equalTo: fontSizeTitle.bottomAnchor, constant: 30),
            previewTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            fontSizePreviewLabel.topAnchor.constraint(equalTo: previewTitle.bottomAnchor, constant: 10),
            fontSizePreviewLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            fontSizePreviewLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            fontSizePreviewLabel.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func loadSettings() {
        let launchAtLogin = UserDefaults.standard.bool(forKey: UserDefaultsLaunchAtLoginKey)
        launchAtLoginCheckbox.state = launchAtLogin ? .on : .off

        let fontSize = UserDefaults.standard.object(forKey: UserDefaultsFontSizeKey) as? Int ?? 11
        fontSizeSlider.integerValue = fontSize
        fontSizeLabel.stringValue = "\(fontSize)"
        updatePreview(fontSize: fontSize)
    }

    @objc private func launchAtLoginChanged() {
        let isEnabled = launchAtLoginCheckbox.state == .on
        UserDefaults.standard.set(isEnabled, forKey: UserDefaultsLaunchAtLoginKey)
        setLaunchAtLogin(enabled: isEnabled)
    }

    @objc private func fontSizeChanged() {
        let fontSize = fontSizeSlider.integerValue
        fontSizeLabel.stringValue = "\(fontSize)"
        UserDefaults.standard.set(fontSize, forKey: UserDefaultsFontSizeKey)
        updatePreview(fontSize: fontSize)
        NotificationCenter.default.post(name: .fontSizeChanged, object: nil, userInfo: ["fontSize": fontSize])
    }

    private func updatePreview(fontSize: Int) {
        let previewText = "↑12.5K/s\n↓34.2K/s"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .medium)
        ]
        fontSizePreviewLabel.attributedStringValue = NSAttributedString(string: previewText, attributes: attrs)
    }

    private func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "register" : "unregister") launch at login: \(error)")
            }
        } else {
            // macOS 12 及更早版本: 使用 AppleScript
            let bundlePath = Bundle.main.bundlePath
            let scriptContent = enabled ?
                "tell application \"System Events\" to make login item at end with properties {path:\"\(bundlePath)\", hidden:false}" :
                "tell application \"System Events\" to delete login item \"\(bundlePath)\""

            if let script = NSAppleScript(source: scriptContent) {
                var errorDict: NSDictionary?
                script.executeAndReturnError(&errorDict)
                if let error = errorDict {
                    print("Launch at login script error: \(error)")
                }
            }
        }
    }
}

extension Notification.Name {
    static let fontSizeChanged = Notification.Name("fontSizeChanged")
}

class NetworkMonitorApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    private var lastRx: Int64 = 0
    private var lastTx: Int64 = 0
    private var lastTime: Date = Date()
    private var isFirstUpdate = true
    private var settingsWindowController: SettingsWindowController?
    private var fontSize: Int = 11

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 检查是否已有实例运行
        if isAlreadyRunning() {
            print("NetworkMonitor is already running.")
            NSApp.terminate(nil)
            return
        }

        // 加载字体大小设置
        fontSize = UserDefaults.standard.object(forKey: UserDefaultsFontSizeKey) as? Int ?? 11

        // 创建状态栏按钮
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem?.menu = menu

        // 监听字体变化通知
        NotificationCenter.default.addObserver(forName: .fontSizeChanged, object: nil, queue: .main) { [weak self] notification in
            if let userInfo = notification.userInfo, let newFontSize = userInfo["fontSize"] as? Int {
                self?.fontSize = newFontSize
            }
        }

        updateNetworkStats()

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSpeed()
        }
    }

    @objc func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow()
    }

    private func getNetworkStats() -> (rx: Int64, tx: Int64)? {
        var totalRx: Int64 = 0
        var totalTx: Int64 = 0

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/netstat")
        task.arguments = ["-i", "-b", "-n"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()

            if let output = String(data: data, encoding: .utf8) {
                let lines = output.split(separator: "\n")
                var seenInterfaces = Set<String>()

                for line in lines {
                    let parts = line.split(separator: " ", omittingEmptySubsequences: true)
                    if parts.count >= 11 {
                        let name = String(parts[0])

                        if name.starts(with: "lo") || seenInterfaces.contains(name) {
                            continue
                        }

                        if parts[1] == "Mtu" || parts[1] == "<Link#" {
                            continue
                        }

                        if let ibytes = Int64(parts[6]), let obytes = Int64(parts[9]) {
                            totalRx += ibytes
                            totalTx += obytes
                            seenInterfaces.insert(name)
                        }
                    }
                }
            }
        } catch {
            return nil
        }

        return (rx: totalRx, tx: totalTx)
    }

    private func updateNetworkStats() {
        if let stats = getNetworkStats() {
            lastRx = stats.rx
            lastTx = stats.tx
            lastTime = Date()
        }
    }

    private func formatSpeed(_ bytesPerSec: Double) -> String {
        if bytesPerSec >= 1024 * 1024 {
            return String(format: "%.1f", bytesPerSec / (1024 * 1024))
        } else if bytesPerSec >= 1024 {
            return String(format: "%.1f", bytesPerSec / 1024)
        } else {
            return String(format: "%.0f", bytesPerSec)
        }
    }

    private func getUnit(_ bytesPerSec: Double) -> String {
        if bytesPerSec >= 1024 * 1024 {
            return "M"
        } else if bytesPerSec >= 1024 {
            return "K"
        } else {
            return "B"
        }
    }

    private func updateSpeed() {
        guard let stats = getNetworkStats() else { return }

        let now = Date()
        let timeInterval = now.timeIntervalSince(lastTime)

        if isFirstUpdate {
            isFirstUpdate = false
            lastRx = stats.rx
            lastTx = stats.tx
            lastTime = now
            DispatchQueue.main.async {
                self.updateDisplay(upVal: "0", downVal: "0", unit: "K")
            }
            return
        }

        if timeInterval > 0 {
            let rxDiff = stats.rx - lastRx
            let txDiff = stats.tx - lastTx

            let rxSpeed = Double(rxDiff) / timeInterval
            let txSpeed = Double(txDiff) / timeInterval

            let downVal = formatSpeed(rxSpeed)
            let upVal = formatSpeed(txSpeed)
            let unit = getUnit(max(rxSpeed, txSpeed))

            DispatchQueue.main.async {
                self.updateDisplay(upVal: upVal, downVal: downVal, unit: unit)
            }

            lastRx = stats.rx
            lastTx = stats.tx
            lastTime = now
        }
    }

    private func updateDisplay(upVal: String, downVal: String, unit: String) {
        let upLine = "↑\(upVal)\(unit)/s"
        let downLine = "↓\(downVal)\(unit)/s"

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .medium),
            .foregroundColor: NSColor.white
        ]

        let upAttr = NSAttributedString(string: upLine, attributes: attrs)
        let downAttr = NSAttributedString(string: downLine, attributes: attrs)

        let width = max(upAttr.size().width, downAttr.size().width) + 4

        let imageSize = NSSize(width: width, height: 24)
        let image = NSImage(size: imageSize)
        image.lockFocus()

        upAttr.draw(at: NSPoint(x: width - upAttr.size().width - 2, y: 10))
        downAttr.draw(at: NSPoint(x: width - downAttr.size().width - 2, y: 0))

        image.unlockFocus()

        statusItem?.button?.image = image
        statusItem?.button?.title = ""
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = NetworkMonitorApp()
app.delegate = delegate

app.run()
