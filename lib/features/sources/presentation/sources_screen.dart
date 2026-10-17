import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/travel_theme.dart';
import '../../../core/ui/page_components.dart';
import '../../books/book_components.dart';
import '../../books/domain/reference.dart';
import '../../books/book_session.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final model = context.watch<BookSession>(), book = model.book;
    return TravelPage(
      children: [
        const PageHeading(
          number: '12',
          title: '事实与来源',
          description: '核查日期、未知条件、照片授权和地图署名，与内容一起保留。历史资料不重新标记为当前已核实。',
        ),
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('阅读这些资料前', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              ...book.notes.map(
                (note) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(note),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...book.sources.map(
          (source) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SourceLink(source),
                  if (source.description.isNotEmpty) Text(source.description),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('照片与素材', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 15),
        ResponsiveCards(
          minimumWidth: 300,
          children: book.photos
              .where((p) => !p.generated || p.id == book.coverId)
              .map(
                (photo) => PaperCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PhotoCard(photo, height: 170),
                      const SizedBox(height: 9),
                      Text(photo.title),
                      Text(
                        photo.attribution,
                        style: const TextStyle(
                          fontSize: 12,
                          color: TravelTheme.muted,
                        ),
                      ),
                      if (photo.licenseUrl.isNotEmpty)
                        SourceLink(
                          Reference(title: '查看授权条款', url: photo.licenseUrl),
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        const Notice('个人备注、预算和清单保存在本设备，不上传到服务器。备份文件可能包含你的行程安排和个人备注，请自行保管。'),
      ],
    );
  }
}
