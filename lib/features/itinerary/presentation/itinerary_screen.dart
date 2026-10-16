import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/travel_theme.dart';
import '../../../core/ui/page_components.dart';
import '../../../core/ui/value_editor.dart';
import '../../books/domain/travel_day.dart';
import 'itinerary_view_model.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key, this.initialDay});
  final String? initialDay;
  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  @override
  void initState() {
    super.initState();
    _focus();
  }

  @override
  void didUpdateWidget(ItineraryScreen old) {
    super.didUpdateWidget(old);
    if (old.initialDay != widget.initialDay) _focus();
  }

  void _focus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ItineraryViewModel>().focusDay(widget.initialDay);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ItineraryViewModel>();
    return TravelPage(
      key: PageStorageKey('itinerary:${model.book.id}'),
      children: [
        PageHeading(
          number: '02',
          title: '每日行程',
          description: '路线、补能与今晚落脚，一天一天翻。备注保存在本设备。',
          action: OutlinedButton.icon(
            onPressed: model.toggleAll,
            icon: const Icon(Icons.unfold_more),
            label: const Text('展开／收起全部'),
          ),
        ),
        if (model.selectedDay != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.go('/book/${model.book.id}/itinerary'),
              icon: const Icon(Icons.view_list_outlined),
              label: const Text('显示全部日期'),
            ),
          ),
        ValueEditor(
          key: ValueKey('itinerary-search:${model.book.id}'),
          label: '搜索每日行程',
          numeric: false,
          value: model.query,
          onChanged: model.search,
        ),
        const SizedBox(height: 14),
        SelectionField(
          label: '行程日期',
          value: model.selectedDay ?? 'all',
          options: {
            'all': '全部日期',
            for (final day in model.variant.days)
              day.id: '${day.label} · ${day.title}',
          },
          onChanged: (value) => model.focusDay(value == 'all' ? null : value),
          width: 320,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: model.phases
              .map(
                (phase) => ChoiceChip(
                  label: Text(phase),
                  selected: model.phase == phase,
                  onSelected: (_) => model.filterPhase(phase),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        ...model.days.map(
          (day) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _DayCard(
              key: ValueKey(
                '${model.variant.id}:${day.id}:${model.expansionRevision}',
              ),
              day: day,
              model: model,
            ),
          ),
        ),
        if (model.days.isEmpty) const EmptyResult('没有匹配的行程，试试其他关键词或阶段。'),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({super.key, required this.day, required this.model});
  final TravelDay day;
  final ItineraryViewModel model;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      key: PageStorageKey(
        'day-expansion:${model.book.id}:${day.id}:${model.expansionRevision}',
      ),
      initiallyExpanded: model.isExpanded(day.id),
      onExpansionChanged: (v) => model.expand(day.id, v),
      tilePadding: const EdgeInsets.symmetric(horizontal: 19, vertical: 7),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      leading: Container(
        width: 54,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: TravelTheme.forest.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          day.label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: TravelTheme.forest),
        ),
      ),
      title: Text(
        day.title,
        style: const TextStyle(fontWeight: FontWeight.w600, height: 1.5),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          '${day.phase} · ${day.geography}',
          style: const TextStyle(fontSize: 11, color: TravelTheme.muted),
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              Text(
                day.focus,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(day.detail),
              const SizedBox(height: 18),
              FactList(day.facts),
              Text('今晚落脚', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('${day.overnight.modeLabel} · ${day.overnight.title}'),
              Text('${day.overnight.region}\n${day.overnight.address}'),
              Notice('${day.overnight.status}。${day.overnight.note}'),
              if (day.overnight.source != null)
                SourceLink(day.overnight.source!),
              if (day.overnight.backup != null) ...[
                Text(
                  '备用酒店 · ${day.overnight.backup!.title}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${day.overnight.backup!.address}\n${day.overnight.backup!.note}',
                ),
                if (day.overnight.backup!.source != null)
                  SourceLink(day.overnight.backup!.source!),
              ],
              for (final event in day.events) ...[
                const Divider(),
                Text(
                  '${event.time} · ${event.place}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(event.activity),
                const SizedBox(height: 8),
                FactList(event.facts),
              ],
              if (day.navigation.isNotEmpty) ...[
                const Divider(),
                Text('地图与分段依据', style: Theme.of(context).textTheme.titleMedium),
                ...day.navigation.map(
                  (ref) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SourceLink(ref),
                      if (ref.description.isNotEmpty)
                        Text(
                          ref.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: TravelTheme.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ValueEditor(
                key: ValueKey('note:${model.book.id}:${day.id}'),
                label: '${day.label} 个人备注',
                numeric: false,
                maxLines: 6,
                maxLength: 4000,
                value: model.note(day.id),
                onChanged: (value) => unawaited(model.saveNote(day.id, value)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
