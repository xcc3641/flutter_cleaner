import Cocoa
import FlutterMacOS
import Darwin

public class MacOSTrashPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "macos_trash", binaryMessenger: registrar.messenger)
    registrar.addMethodCallDelegate(MacOSTrashPlugin(), channel: channel)
  }

  /// Stable codes are localized on the Dart side; `message` carries system text only.
  private struct PluginFailure: Error {
    let code: String
    let path: String
    var message: String? = nil
  }

  private func failure(_ code: String, _ path: String) -> PluginFailure {
    PluginFailure(code: code, path: path)
  }

  private func directoryID(_ path: String) throws -> String {
    var info = stat()
    guard Darwin.lstat(path, &info) == 0 else {
      throw PluginFailure(code: "CLEANUP_ERROR", path: path, message: String(cString: strerror(errno)))
    }
    guard (info.st_mode & S_IFMT) == S_IFDIR else {
      throw failure("REPLACED_OR_LINKED", path)
    }
    return "\(info.st_dev):\(info.st_ino)"
  }

  private func snapshot(root: String, project: String, build: String) throws -> [String: String] {
    guard (project == root || root == "/" || project.hasPrefix(root + "/")), build == project + "/build" else {
      throw failure("OUT_OF_SCOPE", build)
    }
    // lstat every ancestor immediately before the operation, not just build.
    var current = build
    while true {
      _ = try directoryID(current)
      guard URL(fileURLWithPath: current).standardizedFileURL.path == current,
            URL(fileURLWithPath: current).resolvingSymlinksInPath().path == current else {
        throw failure("SYMLINK_OR_NONCANONICAL", current)
      }
      let parent = (current as NSString).deletingLastPathComponent
      if parent == current { break }
      current = parent
    }
    return ["root": root, "project": project, "build": build,
            "rootID": try directoryID(root), "projectID": try directoryID(project),
            "buildID": try directoryID(build)]
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Directory identity is required", details: nil))
      return
    }
    do {
      switch call.method {
      case "inspectBuild":
        guard let root = args["root"] as? String, let project = args["project"] as? String,
              let build = args["build"] as? String else {
          throw failure("MISSING_IDENTITY", "")
        }
        result(try snapshot(root: root, project: project, build: build))
      case "moveToTrash", "permanentlyDelete":
        guard let path = args["path"] as? String, let expected = args["identity"] as? [String: String],
              let root = expected["root"], let project = expected["project"],
              let build = expected["build"], path == build else {
          throw failure("MISSING_SCAN_IDENTITY", args["path"] as? String ?? "")
        }
        let actual = try snapshot(root: root, project: project, build: build)
        guard actual == expected else {
          throw failure("CHANGED_SINCE_SCAN", path)
        }
        // FileManager operates by path: a residual TOCTOU window remains after
        // this check. This is not a descriptor-relative atomic deletion API.
        let url = URL(fileURLWithPath: path)
        if call.method == "moveToTrash" {
          try FileManager.default.trashItem(at: url, resultingItemURL: nil)
        } else {
          try FileManager.default.removeItem(at: url)
        }
        result(nil)
      case "reveal":
        guard let path = args["path"] as? String else {
          throw failure("INVALID_ARGUMENT", "")
        }
        guard FileManager.default.fileExists(atPath: path) else {
          throw PluginFailure(code: "CLEANUP_ERROR", path: path,
                              message: String(cString: strerror(ENOENT)))
        }
        DispatchQueue.main.async {
          NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch let error as PluginFailure {
      result(FlutterError(code: error.code, message: error.message, details: error.path))
    } catch {
      result(FlutterError(code: "CLEANUP_ERROR", message: error.localizedDescription,
                          details: args["path"] ?? args["build"]))
    }
  }
}
