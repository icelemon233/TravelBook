import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/page_components.dart';
import '../../books/book_components.dart';
import '../../books/domain/reference.dart';
import '../../budget/budget_summary.dart';
import '../../books/book_session.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final model = context.watch<BudgetSummary>(),
        book = context.watch<BookSession>().book,
        comparison = model.returnComparison;
    return TravelPage(
      children: [
        PageHeading(
          number: '07',
          title: '两种返程',
          description:
              '高德核对日期：${book.returnOptions?.checkedDate ?? ''}。对比独立于当前主行程，不修改主地图、住宿清单或总预算。',
        ),
        if (comparison != null) ...[
          ResponsiveCards(
            minimumWidth: 350,
            children: comparison.options
                .map(
                  (estimate) => PaperCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          estimate.option.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(estimate.option.subtitle),
                        const SizedBox(height: 12),
                        Text(estimate.option.route),
                        Notice(
                          '全程 ${estimate.days}天 · 返程 ${estimate.legs.length}天\n返程 ${estimate.km.toStringAsFixed(1)}km · ${estimate.minutes ~/ 60}小时${estimate.minutes % 60}分钟 · 通行估算 ¥${estimate.tolls.toStringAsFixed(0)}',
                        ),
                        Text(estimate.option.summary),
                        const SizedBox(height: 8),
                        Text(estimate.option.note),
                        if (estimate.movedExtra)
                          const Notice('原17天版的额外机动日已转作第5天返程，没有额外增加第18天。'),
                        for (final entry in estimate.legs.indexed) ...[
                          const Divider(),
                          Text(
                            'Day ${estimate.firstDay + entry.$1} · ${entry.$2.from} → ${entry.$2.to}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text('${entry.$2.fromRegion} → ${entry.$2.toRegion}'),
                          Text(
                            '${entry.$2.km.toStringAsFixed(1)}km · ${entry.$2.minutes ~/ 60}小时${entry.$2.minutes % 60}分钟 · ¥${entry.$2.tolls.toStringAsFixed(0)}',
                          ),
                          Text(entry.$2.roads),
                          Text(
                            '当晚：${switch (estimate.option.nightModes[entry.$1]) {
                              'car' => '拟车宿',
                              'hotel' => '拟酒店',
                              _ => '回家',
                            }} · 具体落脚点待定',
                          ),
                          SourceLink(
                            Reference(title: '高德原始路线', url: entry.$2.url),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          Notice(
            comparison.delta == null
                ? '请先修正预算参数，再比较费用差额。'
                : '按当前预算参数，B 比 A ${comparison.delta! >= 0 ? '增加' : '减少'}约 ¥${comparison.delta!.abs().toStringAsFixed(2)}；${comparison.dayDifference == 0 ? '两案天数相同' : 'B 多 ${comparison.dayDifference} 天'}。差额只比较两条返程的不同费用，未重复加入共同的去程费用。',
          ),
        ],
        if (book.returnOptions != null) Notice(book.returnOptions!.note),
        const Notice('打开高德后，按所列道路选择路线；推荐序号、收费和预计车程会变化。公共计时参考点不是已经确认的酒店或车宿点。'),
      ],
    );
  }
}
