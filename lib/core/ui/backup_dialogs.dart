import 'package:flutter/material.dart';

import '../../features/export/presentation/actions_view_model.dart';

Future<void> requestBackupImport(
  BuildContext context,
  ActionsViewModel actions,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: const Text('导入本地备份'),
      content: const Text('导入会替换本设备的备注、清单和预算。需要保留当前内容时，请先导出备份。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: const Text('选择备份文件'),
        ),
      ],
    ),
  );
  if (confirmed == true) await actions.importBackup();
}

Future<void> requestBackupPaste(
  BuildContext context,
  ActionsViewModel actions,
) async {
  final controller = TextEditingController();
  final content = await showDialog<String>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: const Text('粘贴备份内容'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('导入会替换当前本地资料，请先备份。'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 9,
              decoration: const InputDecoration(labelText: '备份文件的完整内容'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialog, controller.text),
          child: const Text('导入'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (content != null) await actions.importText(content);
}
