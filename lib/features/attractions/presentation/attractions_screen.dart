import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/travel_theme.dart';
import '../../../core/ui/page_components.dart';
import '../../books/book_components.dart';
import 'attractions_view_model.dart';

class AttractionsScreen extends StatelessWidget {
  const AttractionsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final model = context.watch<AttractionsViewModel>();
    return TravelPage(
      children: [
        PageHeading(
          number: '04',
          title: '旅途景点',
          description: '${model.count} 处景点。主要游览、沿途短停和可选点分开看，按日期回到行程。',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: model.regions
              .map(
                (r) => ChoiceChip(
                  label: Text(r),
                  selected: model.region == r,
                  onSelected: (_) => model.selectRegion(r),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        ResponsiveCards(
          minimumWidth: 330,
          children: model.groups.map((group) {
            final photo = model.book.photo(group.photoId);
            return PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photo != null) ...[
                    PhotoCard(photo, height: 190),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    group.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    group.region,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TravelTheme.muted,
                    ),
                  ),
                  if (group.caption.isNotEmpty)
                    Text(
                      group.caption,
                      style: const TextStyle(
                        fontSize: 11,
                        color: TravelTheme.muted,
                      ),
                    ),
                  for (final spot in group.spots) ...[
                    const Divider(),
                    Text(
                      spot.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      spot.type,
                      style: const TextStyle(
                        fontSize: 11,
                        color: TravelTheme.copper,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(spot.description),
                    SourceLink(spot.source),
                    Wrap(
                      spacing: 6,
                      children: model
                          .days(spot)
                          .entries
                          .map(
                            (day) => ActionChip(
                              label: Text(day.value),
                              onPressed: () => context.go(
                                '/book/${model.book.id}/itinerary?day=${Uri.encodeQueryComponent(day.key)}',
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    if (model.days(spot).isEmpty)
                      const Text(
                        '当前版本未安排 · 保留为备选',
                        style: TextStyle(
                          fontSize: 11,
                          color: TravelTheme.muted,
                        ),
                      ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
        const Notice(
          '婺源北线的虹关与漳村二选一；桃花潭在15天版中取消。历史配图附作者与授权，不能据此判断当前天气、施工或开放状态。',
        ),
      ],
    );
  }
}
