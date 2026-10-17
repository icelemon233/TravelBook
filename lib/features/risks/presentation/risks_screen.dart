import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/travel_theme.dart';
import '../../../core/ui/page_components.dart';
import '../../../core/ui/value_editor.dart';
import 'risk_view_model.dart';

class RisksScreen extends StatelessWidget {
  const RisksScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final model = context.watch<RiskViewModel>();
    return TravelPage(
      children: [
        PageHeading(
          number: '10',
          title: '风险与应对',
          description: '保留原路书的触发条件和行动建议，按日期、等级、类别筛选。',
          action: TextButton.icon(
            onPressed: model.reset,
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('重置筛选'),
          ),
        ),
        ValueEditor(
          key: const ValueKey('risk-search'),
          label: '搜索风险关键词',
          numeric: false,
          value: model.query,
          onChanged: (v) => model.update(query: v),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SelectionField(
              label: '风险日期',
              value: model.date,
              options: {for (final d in model.dates) d: d},
              onChanged: (v) => model.update(date: v),
            ),
            SelectionField(
              label: '风险等级',
              value: model.level,
              options: const {'全部': '全部', '高': '高', '中': '中', '低': '低'},
              onChanged: (v) => model.update(level: v),
            ),
            SelectionField(
              label: '风险类别',
              value: model.category,
              options: {for (final c in model.categories) c: c},
              onChanged: (v) => model.update(category: v),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('高等级优先'),
          value: model.highFirst,
          onChanged: (v) => model.update(highFirst: v),
        ),
        Text(
          '当前 ${model.risks.length} 项',
          style: const TextStyle(color: TravelTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        ...model.risks.map(
          (risk) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 9,
                    runSpacing: 7,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(label: Text('${risk.id} · ${risk.level}')),
                      Text(
                        risk.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  Text(
                    '${risk.scope} · ${risk.category}',
                    style: const TextStyle(
                      color: TravelTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(risk.reason),
                  Notice('行动：${risk.action}'),
                  Text(
                    '触发条件：${risk.trigger}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (model.risks.isEmpty) const EmptyResult('没有匹配的风险记录。'),
      ],
    );
  }
}
