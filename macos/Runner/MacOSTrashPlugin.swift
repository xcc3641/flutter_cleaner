import Cocoa
import FlutterMacOS

public class MacOSTrashPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "macos_trash", binaryMessenger: registrar.messenger)
    let instance = MacOSTrashPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "moveToTrash":
      guard let filePath = call.arguments as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "File path is required", details: nil))
        return
      }
      moveToTrash(filePath: filePath, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func moveToTrash(filePath: String, result: @escaping FlutterResult) {
    let fileManager = FileManager.default
    let url = URL(fileURLWithPath: filePath)
    
    do {
      try fileManager.trashItem(at: url, resultingItemURL: nil)
      result(nil)
    } catch {
      result(FlutterError(code: "TRASH_ERROR", message: error.localizedDescription, details: nil))
    }
  }
}
