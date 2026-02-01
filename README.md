# NetworkMonitor

一个轻量级的 macOS 菜单栏网络监控工具，实时显示上传和下载速度。

## 功能

- 📊 实时显示网络上传/下载速度
- 🎯 轻量级设计，可执行文件仅约 90KB
- 📍 常驻菜单栏，不占用 Dock 空间
- ⚡ 使用 Swift 原生开发，性能优异

## 显示效果

菜单栏显示两行网速：
```
↑12.5K/s
↓345.2K/s
```

## 编译

```bash
cd NetworkMonitor
swiftc -o NetworkMonitor Sources/main.swift -framework Cocoa -O
```

## 运行

```bash
./NetworkMonitor
```

右键菜单栏图标选择 "退出" 或按 `Cmd+Q` 退出程序。

## 系统要求

- macOS 10.15 或更高版本
- Xcode Command Line Tools

## 许可

MIT License
