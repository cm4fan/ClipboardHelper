import SwiftUI
import AppKit
import ServiceManagement

@main
struct ClipboardHelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var clipboardMonitor = ClipboardMonitor()
    private let prefix = "**[VPN, PROXY]** "
    private let launchAtLoginKey = "LaunchAtLogin"
    private let helperBundleID = "com.yourcompany.ClipboardHelperLauncher"
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()
        setupClipboardMonitor()
        updateStatusItemIcon()
        setupLoginItem()
    }
    
    // MARK: - Menu Setup
    private func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        let menu = NSMenu()
        
        // Toggle monitoring
        let toggleItem = NSMenuItem(
            title: NSLocalizedString("Enable Monitoring", comment: ""),
            action: #selector(toggleMonitoring(_:)),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleItem.state = clipboardMonitor.isEnabled ? .on : .off
        menu.addItem(toggleItem)
        
        
        // Launch at login
        let launchItem = NSMenuItem(
            title: NSLocalizedString("Launch at Login", comment: ""),
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = launchAtLogin ? .on : .off
        menu.addItem(launchItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // About
        menu.addItem(NSMenuItem(
            title: NSLocalizedString("About Clipboard Helper", comment: ""),
            action: #selector(showAbout),
            keyEquivalent: ""
        ))
        
        // Quit
        menu.addItem(NSMenuItem(
            title: NSLocalizedString("Quit", comment: ""),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        
        statusItem.menu = menu
    }
    
    // MARK: - Clipboard Monitoring
    private func setupClipboardMonitor() {
        clipboardMonitor.onClipboardChange = { [weak self] text in
            guard let self = self,
                  self.clipboardMonitor.isEnabled,
                  text.contains("figma.com"),
                  !text.hasPrefix(self.prefix) else { return }
            
            let newText = self.prefix + text
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(newText, forType: .string)
        }
        clipboardMonitor.start()
    }
    
    private func updateStatusItemIcon() {
        let imageName = clipboardMonitor.isEnabled ?
            "clipboard.fill" :
            "clipboard"
        
        let config = NSImage.SymbolConfiguration(
            pointSize: 17,
            weight: .regular,
            scale: .small
        )
        
        guard let image = NSImage(
            systemSymbolName: imageName,
            accessibilityDescription: nil
        )?.withSymbolConfiguration(config) else { return }
        
        statusItem.button?.image = image
        statusItem.button?.imageScaling = .scaleProportionallyDown
    }
    
    // MARK: - Launch at Login Logic
    private var launchAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: launchAtLoginKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: launchAtLoginKey)
            updateLoginItem(enabled: newValue)
        }
    }
    
    private func setupLoginItem() {
        updateLoginItem(enabled: launchAtLogin)
    }
    
    private func updateLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Error managing login items: \(error.localizedDescription)")
            }
        } else {
            SMLoginItemSetEnabled(helperBundleID as CFString, enabled)
        }
    }
    
    // MARK: - Actions
    @objc private func toggleMonitoring(_ sender: NSMenuItem) {
        clipboardMonitor.isEnabled.toggle()
        sender.state = clipboardMonitor.isEnabled ? .on : .off
        updateStatusItemIcon()
    }
    
    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        launchAtLogin.toggle()
        sender.state = launchAtLogin ? .on : .off
    }
    
    @objc private func showAbout() {
        AboutWindowController.shared.showWindow(nil)
        AboutWindowController.shared.window?.makeKeyAndOrderFront(nil)
    }
}

class ClipboardMonitor {
    var isEnabled = true
    var onClipboardChange: ((String) -> Void)?
    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, self.isEnabled else { return }
            
            let pasteboard = NSPasteboard.general
            guard pasteboard.changeCount != self.lastChangeCount else { return }
            
            self.lastChangeCount = pasteboard.changeCount
            guard let string = pasteboard.string(forType: .string) else { return }
            
            self.onClipboardChange?(string)
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
