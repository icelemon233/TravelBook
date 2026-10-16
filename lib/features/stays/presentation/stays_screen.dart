import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/travel_theme.dart';
import '../../../core/ui/page_components.dart';
import '../../books/presentation/book_view_model.dart';

class StaysScreen extends StatelessWidget {
  const StaysScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final model = context.watch<BookViewModel>();
    return TravelPage(
      children: [
        const PageHeading(
          number: '05',
          title: '今晚住哪里',
          description: '住宿随当前行程方案更新。酒店、停车场和备用落脚点分别记录，不把停车设施当作车宿许可。',
        ),
        ...model.variant.days
            .where((day) => !day.isPreparation)
            .map(
              (day) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PaperCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Chip(
                            label: Text(
                              '${day.label} · ${day.overnight.modeLabel}',
                            ),
                          ),
                          Text(
                            day.overnight.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        day.overnight.region,
                        style: const TextStyle(color: TravelTheme.muted),
                      ),
                      Text(day.overnight.address),
                      const SizedBox(height: 9),
                      Text(day.overnight.reason),
                      Notice('${day.overnight.status}。${day.overnight.note}'),
                      if (day.overnight.source != null)
                        SourceLink(day.overnight.source!),
                      if (day.overnight.backup != null) ...[
                        const Divider(),
                        Text(
                          '车宿不合适时 · ${day.overnight.backup!.title}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${day.overnight.backup!.region}\n${day.overnight.backup!.address}\n${day.overnight.backup!.note}',
                        ),
                        if (day.overnight.backup!.source != null)
                          SourceLink(day.overnight.backup!.source!),
                      ],
                      TextButton.icon(
                        onPressed: () => context.go(
                          '/book/${model.book.id}/itinerary?day=${Uri.encodeQueryComponent(day.id)}',
                        ),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('查看这一天'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
