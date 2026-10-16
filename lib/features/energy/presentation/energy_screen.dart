import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/page_components.dart';
import '../../../core/ui/value_editor.dart';
import 'energy_view_model.dart';

class EnergyScreen extends StatelessWidget {
  const EnergyScreen({super.key});
  static const labels = {
    'range': '实际续航（km）',
    'start-soc': '出发 SOC（%）',
    'reserve-soc': '抵达保留 SOC（%）',
    'derate': '高速／低温折减（%）',
    'battery': '电池容量（kWh）',
    'bed-soc': '睡前 SOC（%）',
    'night-use': '整夜总耗电（kWh）',
  };
  @override
  Widget build(BuildContext context) {
    final model = context.watch<EnergyViewModel>();
    Widget fields(List<String> ids) => ResponsiveCards(
      minimumWidth: 230,
      children: ids
          .map(
            (id) => ValueEditor(
              key: ValueKey('energy:$id'),
              label: labels[id]!,
              value: model.values[id] ?? '',
              maxLength: 32,
              onChanged: (value) => unawaited(model.edit(id, value)),
            ),
          )
          .toList(),
    );
    return TravelPage(
      children: [
        const PageHeading(
          number: '08',
          title: '电量与补能',
          description: '行驶窗口和整夜空调分开估算。没有电池容量或实测夜耗时，不生成早晨 SOC 结论。',
        ),
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('行车补能窗口', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 18),
              fields(['range', 'start-soc', 'reserve-soc', 'derate']),
              Notice(model.rangeLabel, warning: model.distance == null),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('车宿一晚之后', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 18),
              fields(['battery', 'bed-soc', 'night-use']),
              Notice(model.morningLabel, warning: model.nightWarning),
            ],
          ),
        ),
        const Notice(
          '150–180km 是原攻略的保守补能规划窗口，不是车辆保证里程。提前核对主站与备用站的接口、开放时间、近期状态和可达余量；慢充不能只凭“有插座”判断。',
        ),
        const Notice(
          '模型用于粗算，不替代本车实测。睡前电量还需覆盖夜耗、次日路程与备用站；睡不好、夜耗不明或停车不允许留宿时改住酒店。',
        ),
      ],
    );
  }
}
