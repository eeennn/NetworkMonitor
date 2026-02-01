#!/usr/bin/env swift

import Cocoa
import Foundation

class NetworkMonitorApp: NSObject {
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    private var lastRx: Int64 = 0
    private var lastTx: Int64 = 0
    private var lastTime: Date = Date()
    private var isFirstUpdate = true

    func run() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu

        updateNetworkStats()

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSpeed()
        }

        NSApplication.shared.run()
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
        // 创建两行文字
        let upLine = "↑\(upVal)\(unit)/s"
        let downLine = "↓\(downVal)\(unit)/s"

        // 使用 NSAttributedString 精确控制每行位置
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white
        ]

        let upAttr = NSAttributedString(string: upLine, attributes: attrs)
        let downAttr = NSAttributedString(string: downLine, attributes: attrs)

        // 计算宽度
        let width = max(upAttr.size().width, downAttr.size().width) + 4

        // 创建图像
        let imageSize = NSSize(width: width, height: 24)
        let image = NSImage(size: imageSize)
        image.lockFocus()

        // 绘制上传（上面，右对齐）
        upAttr.draw(at: NSPoint(x: width - upAttr.size().width - 2, y: 10))
        // 绘制下载（下面，右对齐）
        downAttr.draw(at: NSPoint(x: width - downAttr.size().width - 2, y: 0))

        image.unlockFocus()

        // 设置图像
        statusItem?.button?.image = image
        statusItem?.button?.title = ""
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let monitor = NetworkMonitorApp()
monitor.run()
