import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/travel_theme.dart';
import 'domain/reference.dart';
import 'reference_actions.dart';

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
          : () => unawaited(context.read<ReferenceActions>().open(reference)),
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
