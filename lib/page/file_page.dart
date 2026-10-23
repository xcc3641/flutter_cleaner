import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_cleaner/file_utils.dart';
import 'package:flutter_cleaner/l10n/l10n.dart';
import 'package:flutter_cleaner/main.dart' show accentColor, dangerColor;
import 'package:flutter_cleaner/riverpod/project.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart' as intl;

const _digits = TextStyle(fontSize: 13, fontFeatures: [FontFeature.tabularFigures()]);

class FilePage extends HookConsumerWidget {
  const FilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);
    final state = ref.watch(projectStateProvider);
    final directory = ref.watch(sCacheDirProvider);
    final error = ref.watch(operationErrorProvider);
    final permanent = ref.watch(isDirectlyRemovePrefProvider);
    final busy = ref.watch(cleanupBusyProvider);
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final l10n = context.l10n;
    useEffect(() {
      Future.microtask(() {
        if (ref.read(sCacheDirProvider).isNotEmpty) {
          ref.read(projectListProvider.notifier).refresh(ref.read(sCacheDirProvider));
        }
      });
      return null;
    }, const []);
    final calculated = directory.isNotEmpty && (state == ProjectStateType.finished || state == ProjectStateType.empty);
    return Column(children: [
      Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
        child: Row(children: [
          Icon(Icons.folder_outlined, size: 16, color: secondary), const SizedBox(width: 8),
          Expanded(child: Tooltip(message: directory.isEmpty ? l10n.projectFolder : directory,
            child: Text(directory.isEmpty ? l10n.flutterProjects : directory, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: secondary)))),
          const SizedBox(width: 20),
          Text(calculated ? l10n.cleanableSpaceTotal(FileUtils.formatFileSize(projects.fold<int>(0, (sum, p) => sum + p.size)))
              : state == ProjectStateType.error ? l10n.sizeUnavailable : l10n.cleanableSpace,
            style: _digits.copyWith(color: calculated ? null : secondary, fontSize: 12)),
        ])),
      if (error != null) Container(width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 140),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        color: dangerColor.withValues(alpha: .08),
        child: SingleChildScrollView(child: SelectableText(error,
          style: const TextStyle(fontSize: 12, color: dangerColor)))),
      Expanded(child: _content(context, ref, state, projects, directory)),
      Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
        child: Row(children: [
          Expanded(child: Text(permanent ? l10n.deletePermanentlyHint : l10n.moveToTrashHint,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: permanent ? dangerColor : secondary))),
          const SizedBox(width: 8),
          Text(l10n.deleteImmediately, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 6),
          SizedBox(width: 40, child: Transform.scale(scale: .7, child: Switch(
            key: const ValueKey('direct-delete-switch'), value: permanent,
            activeTrackColor: dangerColor,
            onChanged: busy || state == ProjectStateType.loading ? null
                : (value) => ref.read(isDirectlyRemovePrefProvider.notifier).state = value,
          ))),
        ])),
    ]);
  }

  Widget _content(BuildContext context, WidgetRef ref, ProjectStateType state,
      List<FileInfo> projects, String directory) {
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final l10n = context.l10n;
    if (state == ProjectStateType.loading) {
      final current = ref.watch(projectScanProgressProvider);
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
        mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 160, child: LinearProgressIndicator(minHeight: 3, color: accentColor)),
          const SizedBox(height: 20),
          Text(l10n.scanningProjects, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Tooltip(message: current, child: Text(current, maxLines: 2, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: secondary))),
        ],
      )));
    }
    if (state != ProjectStateType.finished || projects.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
        mainAxisSize: MainAxisSize.min, children: [
          Icon(state == ProjectStateType.error ? Icons.error_outline : Icons.folder_open_rounded,
            size: 36, color: state == ProjectStateType.error ? dangerColor : secondary.withValues(alpha: .5)),
          const SizedBox(height: 16),
          Text(directory.isEmpty ? l10n.chooseFolderPrompt
              : state == ProjectStateType.error ? l10n.scanFailed : l10n.noBuildCaches,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          if (directory.isNotEmpty && state == ProjectStateType.empty) ...[
            const SizedBox(height: 8),
            Text(l10n.noBuildCachesDetail, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: secondary)),
          ],
        ],
      )));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
        child: Text(l10n.foundProjects(projects.length), style: TextStyle(fontSize: 11, color: secondary))),
      Expanded(child: ListView.builder(itemCount: projects.length, itemBuilder: (context, index) =>
        ProjectRow(project: projects[index], onDelete: () => _confirmCleanup(context, ref, projects[index])))),
    ]);
  }

  Future<void> _confirmCleanup(BuildContext context, WidgetRef ref, FileInfo project) async {
    final permanent = ref.read(isDirectlyRemovePrefProvider);
    final l10n = context.l10n;
    final action = permanent ? l10n.deletePermanently : l10n.moveToTrash;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(permanent ? l10n.deletePermanentlyTitle : l10n.moveToTrashTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      content: SizedBox(width: 360, child: Text(permanent
        ? l10n.deletePermanentlyMessage(project.name)
        : l10n.moveToTrashMessage(project.name), style: const TextStyle(fontSize: 13))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: permanent ? dangerColor : accentColor),
          onPressed: () => Navigator.pop(context, true), child: Text(action)),
      ],
    ));
    if (confirmed != true || !context.mounted) return;
    final success = await ref.read(projectListProvider.notifier).cleanBuildFolder(project, isDirectlyRemove: permanent);
    if (success && context.mounted && !permanent) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.movedToTrash(project.name))));
    }
  }
}

class ProjectRow extends ConsumerStatefulWidget {
  final FileInfo project;
  final VoidCallback onDelete;
  const ProjectRow({super.key, required this.project, required this.onDelete});
  @override
  ConsumerState<ProjectRow> createState() => _ProjectRowState();
}

class _ProjectRowState extends ConsumerState<ProjectRow> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final busy = ref.watch(cleanupBusyProvider);
    final permanent = ref.watch(isDirectlyRemovePrefProvider);
    final l10n = context.l10n;
    return MouseRegion(onEnter: (_) => setState(() => hovered = true), onExit: (_) => setState(() => hovered = false),
      child: Container(height: 52, padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: hovered ? accentColor.withValues(alpha: .05) : null,
          border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .5)))),
        child: Row(children: [
          const Icon(Icons.folder_outlined, size: 20, color: accentColor), const SizedBox(width: 10),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Tooltip(message: project.path, child: Text(project.path,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: secondary))),
          ])),
          const SizedBox(width: 10),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(FileUtils.formatFileSize(project.size), style: _digits),
            const SizedBox(height: 2),
            Text(intl.DateFormat('yyyy-MM-dd').format(project.lastModified),
              style: TextStyle(fontSize: 11, color: secondary)),
          ]),
          const SizedBox(width: 8),
          // Keep hit targets and keyboard access stable; reveal their affordances on hover/focus.
          SizedBox(width: 68, child: FocusTraversalGroup(child: Row(children: [
            _action(Icons.search_rounded, l10n.showInFinder, hovered ? secondary : secondary.withValues(alpha: .35),
              busy ? null : () => ref.read(projectListProvider.notifier).reveal(project.path)),
            _action(Icons.delete_outline_rounded, permanent ? l10n.deletePermanently : l10n.moveToTrash,
              hovered ? dangerColor : secondary.withValues(alpha: .35), busy ? null : widget.onDelete),
          ]))),
        ])));
  }
  Widget _action(IconData icon, String tooltip, Color color, VoidCallback? action) =>
    SizedBox(width: 34, height: 34, child: IconButton(padding: EdgeInsets.zero,
      tooltip: tooltip, onPressed: action, icon: Icon(icon, size: 17, color: color)));
}
