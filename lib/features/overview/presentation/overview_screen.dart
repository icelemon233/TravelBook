import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/travel_theme.dart';
import '../../../core/ui/page_components.dart';
import '../../books/presentation/book_view_model.dart';
import '../../budget/presentation/budget_view_model.dart';
import '../../preparation/presentation/preparation_view_model.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final model = context.watch<BookViewModel>(),
        budget = context.watch<BudgetViewModel>(),
        preparation = context.watch<PreparationViewModel>();
    final book = model.book,
        variant = model.variant,
        photo = book.photo(book.coverId),
        quote = budget.estimate;
    return TravelPage(
      children: [
        PageHeading(number: '01', title: book.title, description: book.edition),
        if (photo != null)
          PhotoCard(
            photo,
            height: MediaQuery.sizeOf(context).width < 600 ? 210 : 340,
          ),
        const SizedBox(height: 20),
        Text(book.subtitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(book.description),
        const SizedBox(height: 22),
        ResponsiveCards(
          minimumWidth: 220,
          children: [
            _Stat(
              '${variant.travelDayCount} 天',
              '当前行程版本',
              Icons.calendar_month_outlined,
            ),
            _Stat(
              quote.valid ? '¥${quote.total.toStringAsFixed(0)}' : '待填写',
              quote.complete ? '预算含机动金' : '已填项目暂计',
              Icons.account_balance_wallet_outlined,
            ),
            _Stat(
              '${preparation.completed} / ${preparation.total}',
              '出发准备',
              Icons.fact_check_outlined,
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (variant.pending)
          const Notice('日喀则办证结果尚未确定，后续路线和住宿保持待定。', warning: true),
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('这一程怎么走', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ...variant.days
                  .where((d) => !d.isPreparation)
                  .map(
                    (day) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: TravelTheme.forest.withValues(
                          alpha: .08,
                        ),
                        child: Text(
                          '${day.number}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: TravelTheme.forest,
                          ),
                        ),
                      ),
                      title: Text(day.title),
                      subtitle: Text(
                        day.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go(
                        '/book/${book.id}/itinerary?day=${Uri.encodeQueryComponent(day.id)}',
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Notice(
          book.isGanwan
              ? '每天纯驾驶目标4–5小时。床车每2–3晚用酒店恢复，充电、用餐与休息另计。'
              : '路线按原参考图的办证结果分流。没有核实的里程、价格和道路继续保留“待核实”。',
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => context.go('/book/${book.id}/itinerary'),
              icon: const Icon(Icons.route),
              label: const Text('查看每日行程'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/book/${book.id}/map'),
              icon: const Icon(Icons.map_outlined),
              label: const Text('查看公路地图'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.icon);
  final String value, label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => PaperCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: TravelTheme.forest, size: 21),
        const SizedBox(height: 15),
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: TravelTheme.muted, fontSize: 12),
        ),
      ],
    ),
  );
}
