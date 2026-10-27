# Surge Dashboard macOS 闪退修复补丁

修复老版本 **Surge Dashboard 5.7.6 (Build 2838)** 在升级到新版 **macOS 27.2** 后，因系统底层 AppKit 私有方法改动导致的启动秒退、界面崩溃问题。

**无需关闭 SIP**，保留 2838 稳定的旧版免签名增强模式，通过本地注入运行时补丁原地复活。

---

### 适用场景与报错特征

macOS 系统大版本更新后，Surge 后台翻墙依然正常，但点击 **Surge Dashboard.app 直接秒退**。通过终端排查抛出以下堆栈特征：

```text
*** Terminating app due to uncaught exception 'NSInvalidArgumentException',
reason: '-[SGDMainWindowController _leadingItemAtDividerIndex:]: unrecognized selector sent to instance ...'
...
AppKit -[_NSSplitViewPartitionAdapter _isSidebar] + 36
AppKit -[_NSSplitViewPartitionAdapter sidebarDividerPosition] + 100
AppKit -[NSTrackingSeparatorToolbarItem _visualPartitionPosition] + 28
AppKit +[NSWindowSectionController leadingPartitionPositionForItem:inWindow:]
```

或涉及 `_trailingItemAtDividerIndex:`、`_isInspector` 等未识别选择器（unrecognized selector）的 `SIGABRT` 崩溃。

---

### 修复原理

新版系统的 AppKit 在初始化带有工具栏分割线的窗口时，会向控制器强行查询私有分栏信息（`_leadingItemAtDividerIndex:` 与 `_trailingItemAtDividerIndex:`）。Surge 5.7.6 2838 编译时的旧版 NIB 界面对象缺少这些方法，直接导致异常抛出。

本项目编译一个轻量级的动态库（`libfix_dashboard.dylib`），在 Dashboard 启动早期直接向根类 `NSObject` 动态注入对应的兜底安全方法，使 AppKit 正常完成窗口排版与渲染，彻底绕过闪退。

---

### 使用方法

#### 1. 彻底退出正在运行的程序

请在运行补丁前确认已完全退出 Surge Dashboard。

#### 2. 确认系统依赖

确保已安装 Xcode 命令行编译工具。若未安装，在终端执行以下命令：

```bash
xcode-select --install
```

#### 3. 运行自动化修补脚本

在终端中依次执行：

```bash
git clone https://github.com/i5NWkv9NH1/Surge-Dashboard-macOS-Crash-Fix.git
cd Surge-Dashboard-macOS-Crash-Fix
chmod +x patch.sh

./patch.sh
```

_注：如果因权限限制提示 `Permission denied`，请使用 `sudo ./patch.sh` 执行。_
# surge-dashboard-5.7.6-macOS-27.2-patch
