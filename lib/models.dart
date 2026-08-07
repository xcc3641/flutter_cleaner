enum ProjectType { flutter, node }

class FileInfo {
  final String name;
  final String path;
  final int size;
  final DateTime lastModified;
  final ProjectType type;
  final List<String> foldersToClean;

  FileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.lastModified,
    required this.type,
    required this.foldersToClean,
  });
}
