import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/travel_theme.dart';
import '../../../core/ui/page_components.dart';
import '../../../core/ui/value_editor.dart';
import '../domain/expense_labels.dart';
import 'budget_view_model.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final model = context.watch<BudgetViewModel>(), quote = model.estimate;
    return TravelPage(
      children: [
        PageHeading(
          number: '06',
          title: '旅行账本',
          description: '按实际人数、住宿和车辆调整。预备金已计入合计，未核实的金额继续留空。',
          action: OutlinedButton.icon(
            onPressed: () => unawaited(model.reset()),
            icon: const Icon(Icons.restart_alt),
            label: const Text('恢复初始预算'),
          ),
        ),
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quote.complete ? '预算合计' : '已填项目暂计',
                style: const TextStyle(color: TravelTheme.muted),
              ),
              const SizedBox(height: 8),
              Text(
                quote.valid ? '¥ ${quote.total.toStringAsFixed(2)}' : '请修正预算参数',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (quote.valid) ...[
                const SizedBox(height: 8),
                Text(
                  '平均每人 ¥${quote.perPerson.toStringAsFixed(2)} · 预备金 ¥${quote.reserve.toStringAsFixed(2)} 已包含',
                ),
                if (model.book.isGanwan)
                  Text(
                    '${quote.days}天 · ${quote.carNights}晚车宿 / ${quote.hotelNights}晚酒店 · 核对里程 ${quote.routeKm.toStringAsFixed(1)}km',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TravelTheme.muted,
                    ),
                  ),
              ],
              if (quote.missing.isNotEmpty)
                Notice(
                  '尚未计入：${quote.missing.join('、')}。当前是已知费用暂计。',
                  warning: true,
                ),
              if (!quote.valid)
                Notice(quote.errors.values.join('；'), warning: true),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...model.variant.budgetWarnings.map(
          (warning) => Notice(warning, warning: true),
        ),
        ...model.groups.map(
          (group) => Padding(
            padding: const EdgeInsets.only(bottom: 17),
            child: PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 18),
                  ResponsiveCards(
                    minimumWidth: 260,
                    children: model.fields
                        .where((f) => f.group == group)
                        .map(
                          (field) => ValueEditor(
                            key: ValueKey(
                              'budget:${model.book.id}:${model.variant.id}:${field.id}',
                            ),
                            label: model.label(field),
                            value: model.input(field),
                            suffix: field.unit.isEmpty ? null : field.unit,
                            error: model.error(field),
                            maxLength: 32,
                            onChanged: (value) =>
                                unawaited(model.edit(field, value)),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (quote.valid)
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('费用明细', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),
                ...quote.items.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Expanded(child: Text(expenseLabel(entry.key))),
                        Text('¥${entry.value.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (model.variant.tickets.isNotEmpty) ...[
          const SizedBox(height: 18),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('门票与来源', style: Theme.of(context).textTheme.titleLarge),
                for (final ticket in model.variant.tickets) ...[
                  const Divider(),
                  Text(
                    '${ticket.name} · ¥${ticket.price.toStringAsFixed(2)} / 人',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(ticket.status),
                  Text(ticket.note),
                  SourceLink(ticket.source),
                ],
              ],
            ),
          ),
        ],
        const Notice('预算参数是可编辑的规划假设，沿用原资料的价格与来源日期。恢复预算只重置金额参数，不清除个人备注或清单。'),
      ],
    );
  }
}
