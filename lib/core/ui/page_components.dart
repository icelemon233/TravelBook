import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/travel_theme.dart';
import '../../features/books/domain/reference.dart';
import '../../features/export/presentation/actions_view_model.dart';

class TravelPage extends StatelessWidget {
  const TravelPage({super.key, required this.children, this.controller});
  final List<Widget> children;
  final ScrollController? controller;
  @override
  Widget build(BuildContext context) => ListView(
    controller: controller,
    padding: EdgeInsets.fromLTRB(
      MediaQuery.sizeOf(context).width < 600 ? 16 : 30,
      22,
      MediaQuery.sizeOf(context).width < 600 ? 16 : 30,
      48,
    ),
    children: children
        .map(
          (child) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1150),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        )
        .toList(),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.number,
    required this.title,
    required this.description,
    this.action,
  });
  final String number, title, description;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number / CINNA TRAVEL BOOK',
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.4,
            color: TravelTheme.copper,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 20,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            ?action,
          ],
        ),
        const SizedBox(height: 9),
        Text(
          description,
          style: const TextStyle(color: TravelTheme.muted, height: 1.7),
        ),
      ],
    ),
  );
}

class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}

class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.warning = false});
  final String text;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: (warning ? TravelTheme.copper : TravelTheme.forest).withValues(
        alpha: .07,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          warning ? Icons.info_outline : Icons.lightbulb_outline,
          size: 20,
          color: warning ? TravelTheme.copper : TravelTheme.forest,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(height: 1.65))),
      ],
    ),
  );
}

class FactList extends StatelessWidget {
  const FactList(this.facts, {super.key});
  final List<TravelFact> facts;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: facts
        .map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.label,
                  style: const TextStyle(
                    color: TravelTheme.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(f.value, style: const TextStyle(height: 1.7)),
              ],
            ),
          ),
        )
        .toList(),
  );
}

class SourceLink extends StatelessWidget {
  const SourceLink(this.reference, {super.key, this.compact = false});
  final Reference reference;
  final bool compact;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 8, vertical: 8),
        alignment: Alignment.centerLeft,
      ),
      onPressed: reference.safeUri == null
          ? null
          : () => unawaited(context.read<ActionsViewModel>().open(reference)),
      icon: const Icon(Icons.open_in_new, size: 15),
      label: Text(reference.title, softWrap: true),
    ),
  );
}

class PhotoCard extends StatelessWidget {
  const PhotoCard(
    this.photo, {
    super.key,
    this.height = 220,
    this.radius = 14,
    this.showCredit = true,
  });
  final TravelPhoto photo;
  final double height, radius;
  final bool showCredit;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          photo.asset,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          semanticLabel: photo.title,
          errorBuilder: (_, _, _) => Container(
            height: height,
            color: TravelTheme.line,
            alignment: Alignment.center,
            child: const Text('配图暂未载入'),
          ),
        ),
      ),
      if (showCredit)
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                photo.attribution,
                style: const TextStyle(fontSize: 10, color: TravelTheme.muted),
              ),
              if (photo.source.isNotEmpty)
                SourceLink(
                  Reference(title: '图片来源', url: photo.source),
                  compact: true,
                ),
            ],
          ),
        ),
    ],
  );
}

class ResponsiveCards extends StatelessWidget {
  const ResponsiveCards({
    super.key,
    required this.children,
    this.minimumWidth = 280,
  });
  final List<Widget> children;
  final double minimumWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = (box.maxWidth / (minimumWidth + 16)).floor().clamp(
            1,
            children.length.clamp(1, 3),
          ),
          width = (box.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: children
            .map((w) => SizedBox(width: width, child: w))
            .toList(),
      );
    },
  );
}

class SelectionField extends StatelessWidget {
  const SelectionField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.width = 235,
  });
  final String label, value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  final double width;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label:$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: options.entries
          .map(
            (e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    ),
  );
}

class EmptyResult extends StatelessWidget {
  const EmptyResult(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 42),
    child: Center(
      child: Text(text, style: const TextStyle(color: TravelTheme.muted)),
    ),
  );
}

Rect? shareOrigin(BuildContext context) {
  final box = context.findRenderObject();
  return box is RenderBox && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
}
