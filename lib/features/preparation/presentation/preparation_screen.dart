import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/travel_theme.dart';
import '../../../core/ui/page_components.dart';
import 'preparation_view_model.dart';

class PreparationScreen extends StatefulWidget {
  const PreparationScreen({super.key});
  @override
  State<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends State<PreparationScreen> {
  final _keys = <String, GlobalKey>{};
  void _jump(PreparationViewModel model) {
    final group = model.jumpNext();
    if (group == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('清单已全部完成。')));
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _keys[group]?.currentContext;
      if (target != null) {
        unawaited(
          Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 350),
            alignment: .15,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<PreparationViewModel>();
    return TravelPage(
      children: [
        PageHeading(
          number: '09',
          title: model.book.isGanwan ? '出发前核对' : '打包清单',
          description: '勾选状态保存在本设备。用备份文件可把个人清单迁移到其他设备。',
          action: OutlinedButton.icon(
            onPressed: () => _jump(model),
            icon: const Icon(Icons.my_location),
            label: const Text('定位下一项'),
          ),
        ),
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${model.completed} / ${model.total} 已完成',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 15),
              LinearProgressIndicator(
                value: model.total == 0 ? 0 : model.completed / model.total,
                minHeight: 6,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('只看未完成'),
                value: model.onlyIncomplete,
                onChanged: model.filterIncomplete,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: model.search,
          decoration: const InputDecoration(
            labelText: '搜索清单',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        ...model.groups
            .where((group) => model.tasks(group).isNotEmpty)
            .map(
              (group) => Padding(
                key: _keys.putIfAbsent(group, GlobalKey.new),
                padding: const EdgeInsets.only(bottom: 16),
                child: PaperCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...model
                          .tasks(group)
                          .map(
                            (task) => Container(
                              decoration: BoxDecoration(
                                color: model.focusedTask == task.id
                                    ? TravelTheme.forest.withValues(alpha: .06)
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: CheckboxListTile(
                                key: ValueKey('task:${task.id}'),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 7,
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  task.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  task.detail,
                                  style: const TextStyle(height: 1.65),
                                ),
                                value: model.checked(task.id),
                                onChanged: (value) {
                                  if (value != null) {
                                    unawaited(model.toggle(task.id, value));
                                  }
                                },
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
        if (model.groups.every((g) => model.tasks(g).isEmpty))
          const EmptyResult('当前筛选下没有待办事项。'),
      ],
    );
  }
}
