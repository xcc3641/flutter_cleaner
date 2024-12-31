import 'package:flutter/material.dart';
import 'package:flutter_cleaner/file_utils.dart';
import 'package:flutter_cleaner/foundation/preferences/prefs.dart';
import 'package:flutter_cleaner/riverpod/project.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences_riverpod/shared_preferences_riverpod.dart';

final isDirectlyRemovePrefProvider = createPrefProvider<bool>(
  prefs: (_) => Pref.instance,
  prefKey: "is_directly_remove",
  defaultValue: false,
);

class FilePage extends HookConsumerWidget {
  const FilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectList = ref.watch(projectListProvider);
    final projectState = ref.watch(projectStateProvider);
    final totalSize = projectList.fold(0, (sum, project) => sum + project.size);

    useEffectOnce(() {
      Future.microtask(() {
        if (ref.read(sCacheDirProvider).isEmpty) {
          return;
        }
        ref.read(projectListProvider.notifier).refresh(ref.read(sCacheDirProvider));
      });
      return null;
    });

    return Column(
      children: [
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.only(right: 30),
          child: Row(
            children: [
              ShadButton.ghost(
                child: Text(
                  ref.watch(sCacheDirProvider),
                  style: ShadTheme.of(context).textTheme.small.copyWith(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  FileUtils.openInFinder(ref.watch(sCacheDirProvider));
                },
              ),
              const Spacer(),
              Text(FileUtils.formatFileSize(totalSize), style: ShadTheme.of(context).textTheme.muted),
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
          child: Text(
            'No projects found',
            style: ShadTheme.of(context).textTheme.h1,
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
        return Stack(
          key: const ValueKey('finished'),
          children: [
            ListView.builder(
              itemCount: projectList.length,
              itemBuilder: (context, index) {
                final project = projectList[index];
                return ListTile(
                  onTap: () {
                    FileUtils.openInFinder(project.path);
                  },
                  title: Text(
                    project.name,
                    style: ShadTheme.of(context).textTheme.small,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(FileUtils.formatFileSize(project.size)),
                      const SizedBox(width: 10),
                      Text(
                        intl.DateFormat('yyyy-MM-dd').format(project.lastModified),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: FittedBox(
                          child: ShadButton.outline(
                            icon: const Icon(
                              Icons.search,
                              size: 30,
                            ),
                            onPressed: () {
                              FileUtils.openInFinder(project.path);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: FittedBox(
                          child: ShadButton.outline(
                            icon: const Icon(
                              Icons.delete_rounded,
                              size: 30,
                            ),
                            onPressed: () => ref
                                .read(projectListProvider.notifier)
                                .cleanBuildFolder(project, isDirectlyRemove: ref.watch(isDirectlyRemovePrefProvider)),
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
                color: Colors.grey.shade100,
                child: ShadSwitch(
                  direction: TextDirection.rtl,
                  value: ref.watch(isDirectlyRemovePrefProvider),
                  onChanged: (v) => ref.read(isDirectlyRemovePrefProvider.notifier).update(v),
                  label: const Text('Delete directly'),
                ),
              ),
            ),
          ],
        );
    }
  }
}
