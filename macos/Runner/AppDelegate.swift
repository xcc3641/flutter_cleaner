import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller : FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
    let registry = controller.registrar(forPlugin: "MacOSTrashPlugin")
    MacOSTrashPlugin.register(with: registry)
  }
}