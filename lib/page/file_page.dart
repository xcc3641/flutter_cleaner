import 'package:flutter/material.dart';
import 'package:flutter_cleaner/file_utils.dart';
import 'package:flutter_cleaner/riverpod/project.dart';
import 'package:flutter_cleaner/models.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shadcn_ui/shadcn_ui.dart';

class FilePage extends HookConsumerWidget {
  const FilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectList = ref.watch(projectListProvider);
    final projectState = ref.watch(projectStateProvider);
    final totalSize = projectList.fold(0, (sum, project) => sum + project.size);
    final dirList = ref.watch(cacheDirListProvider);

    useEffectOnce(() {
      Future.microtask(() {
        if (dirList.isEmpty) {
          return;
        }
        ref.read(projectListProvider.notifier).refresh(dirList);
      });
      return null;
    });

    return Column(
      children: [
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${projectList.length} Projects found',
                style: ShadTheme.of(context).textTheme.small.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Cleanable: ${FileUtils.formatFileSize(totalSize)}',
                style: ShadTheme.of(context).textTheme.muted,
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildContent(context, ref, projectState, projectList),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ProjectStateType state, List<FileInfo> projectList) {
    switch (state) {
      case ProjectStateType.loading:
        return Column(
          key: const ValueKey('loading'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitWanderingCubes(
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 20),
            Text(
              ref.watch(projectScanProgressProvider),
              style: ShadTheme.of(context).textTheme.small.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        );
      case ProjectStateType.empty:
        return Center(
          key: const ValueKey('empty'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text(
                'No cleanable projects found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      case ProjectStateType.error:
        return Center(
          key: const ValueKey('error'),
          child: Text(
            'Error loading projects',
            style: ShadTheme.of(context).textTheme.h1.copyWith(color: Colors.red),
          ),
        );
      case ProjectStateType.finished:
        final isDirectlyRemove = ref.watch(isDirectlyRemoveProvider);
        return Stack(
          key: const ValueKey('finished'),
          children: [
            ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: projectList.length,
              itemBuilder: (context, index) {
                final project = projectList[index];
                return ListTile(
                  onTap: () {
                    FileUtils.openInFinder(project.path);
                  },
                  leading: Icon(
                    project.type == ProjectType.flutter ? Icons.flutter_dash : Icons.javascript,
                    color: project.type == ProjectType.flutter ? Colors.blue : Colors.yellow.shade800,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          style: ShadTheme.of(context).textTheme.small.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          project.type == ProjectType.flutter ? 'Flutter' : 'NodeJS',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    project.foldersToClean.join(', '),
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            FileUtils.formatFileSize(project.size),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            intl.DateFormat('yyyy-MM-dd').format(project.lastModified),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(width: 15),
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: FittedBox(
                          child: ShadButton.outline(
                            leading: const Icon(
                              Icons.delete_rounded,
                              size: 30,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => ref
                                .read(projectListProvider.notifier)
                                .cleanProject(project, isDirectlyRemove: isDirectlyRemove),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ShadSwitch(
                        direction: TextDirection.rtl,
                        value: isDirectlyRemove,
                        onChanged: (v) => ref.read(isDirectlyRemoveProvider.notifier).update(v),
                        label: const Text('Delete directly (Skip Trash)'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }
}
