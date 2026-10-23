// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get flutterProjects => 'Flutter 项目';

  @override
  String get projectFolder => '项目目录';

  @override
  String get chooseFolder => '选择目录';

  @override
  String get chooseProjectFolder => '选择项目目录';

  @override
  String get chooseFolderPrompt => '选择包含 Flutter 项目的目录开始扫描。';

  @override
  String get rescan => '重新扫描';

  @override
  String get viewSourceCode => '查看源代码';

  @override
  String get cleanableSpace => '可清理空间';

  @override
  String cleanableSpaceTotal(String size) {
    return '可清理空间  $size';
  }

  @override
  String get sizeUnavailable => '无法读取大小';

  @override
  String get moveToTrashHint => '移至废纸篓（可恢复）';

  @override
  String get deletePermanentlyHint => '永久删除，不可恢复';

  @override
  String get deleteImmediately => '直接删除';

  @override
  String get scanningProjects => '正在扫描 Flutter 项目…';

  @override
  String get scanFailed => '扫描失败。请检查目录权限后重试。';

  @override
  String get noBuildCaches => '没有发现可清理的 build 缓存。';

  @override
  String get noBuildCachesDetail => '当前目录中的项目都没有可清理的 build 文件。';

  @override
  String foundProjects(int count) {
    return '找到 $count 个可清理项目';
  }

  @override
  String get moveToTrash => '移到废纸篓';

  @override
  String get deletePermanently => '永久删除';

  @override
  String get moveToTrashTitle => '将项目移到废纸篓？';

  @override
  String get deletePermanentlyTitle => '永久删除这些文件？';

  @override
  String moveToTrashMessage(String name) {
    return '“$name”中的 build 文件将移到废纸篓，可在废纸篓中恢复。';
  }

  @override
  String deletePermanentlyMessage(String name) {
    return '“$name”中的 build 文件将被永久删除，无法从废纸篓恢复。';
  }

  @override
  String get cancel => '取消';

  @override
  String movedToTrash(String name) {
    return '已将 $name 的 build 文件移到废纸篓。';
  }

  @override
  String get showInFinder => '在 Finder 中显示';

  @override
  String get errorFolderAccess => '无法访问此目录。请重新选择目录并允许访问。';

  @override
  String errorOpenLink(String url) {
    return '无法打开 $url';
  }

  @override
  String errorCleanup(String error) {
    return '无法完成清理：$error';
  }

  @override
  String errorReveal(String error) {
    return '无法在 Finder 中显示：$error';
  }

  @override
  String errorScan(String error) {
    return '无法扫描：$error';
  }

  @override
  String get errorNotScanned => '目录未经扫描，请重新扫描。';

  @override
  String get errorOutsideSelection => '目录已超出选择范围，请重新扫描。';

  @override
  String get errorReplacedOrLinked => '目录已被替换或包含符号链接，请重新扫描。';

  @override
  String get errorChangedSinceScan => '目录自扫描后已更改，请重新扫描。';

  @override
  String get errorBuildNotDirectory => 'build 目录不是普通目录（不允许符号链接）。';

  @override
  String get errorIdentityUnavailable => '无法验证目录身份。';

  @override
  String get errorIdentityNotVerified => '目录未经身份验证，请重新扫描。';

  @override
  String get errorSymlinkNotAllowed => '不允许符号链接或非规范目录，请重新扫描。';

  @override
  String get errorMissingIdentity => '缺少目录身份。';

  @override
  String get errorMissingScanIdentity => '缺少扫描目录身份，请重新扫描。';
}
