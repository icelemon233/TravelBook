import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/travel_theme.dart';
import '../../../core/ui/page_components.dart';
import '../../books/book_components.dart';
import '../../export/backup_dialogs.dart';
import '../../books/domain/reference.dart';
import '../../export/export_actions.dart';
import '../../preferences/preferences_status.dart';
import 'library_view_model.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final model = context.watch<LibraryViewModel>(),
        actions = context.watch<ExportActions>(),
        status = context.watch<PreferencesStatus>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CINNA / TRAVEL BOOK',
          style: TextStyle(fontSize: 16, letterSpacing: 1.2),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: '本地资料',
            onSelected: (v) {
              if (v == 'export') {
                unawaited(actions.exportBackup(origin: shareOrigin(context)));
              } else if (v == 'recovery') {
                unawaited(actions.exportRecovery(origin: shareOrigin(context)));
              } else {
                unawaited(requestBackupImport(context, actions));
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'export', child: Text('导出本地备份')),
              const PopupMenuItem(value: 'import', child: Text('导入本地备份')),
              if (status.state.recoveryRaw != null)
                const PopupMenuItem(value: 'recovery', child: Text('导出原始恢复副本')),
            ],
          ),
        ],
      ),
      body: TravelPage(
        children: [
          const SizedBox(height: 22),
          if (status.state.error != null)
            Notice(status.state.error!, warning: true),
          Text('把路书带上。', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 12),
          const Text(
            '行程、地图、预算与出发清单，放在同一本旅行册里。',
            style: TextStyle(
              color: TravelTheme.muted,
              fontSize: 16,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 26),
          TextField(
            onChanged: model.search,
            decoration: const InputDecoration(
              labelText: '查找路书',
              prefixIcon: Icon(Icons.search),
              hintText: '赣皖、江门、西藏、拉萨…',
            ),
          ),
          const SizedBox(height: 26),
          ResponsiveCards(
            minimumWidth: 360,
            children: model.books
                .map(
                  (book) => Semantics(
                    button: true,
                    label: '打开${book.title}路书',
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.go('/book/${book.id}/overview'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PhotoCard(
                              book.cover,
                              height: 230,
                              radius: 0,
                              showCredit: false,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(23),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book.edition,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: TravelTheme.copper,
                                    ),
                                  ),
                                  const SizedBox(height: 9),
                                  Text(
                                    book.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(book.subtitle),
                                  const SizedBox(height: 12),
                                  Text(
                                    book.description,
                                    style: const TextStyle(
                                      color: TravelTheme.muted,
                                      height: 1.7,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.menu_book,
                                        size: 19,
                                        color: TravelTheme.forest,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('打开路书'),
                                      const Spacer(),
                                      const Icon(Icons.arrow_forward, size: 19),
                                    ],
                                  ),
                                  const Divider(),
                                  Text(
                                    book.cover.attribution,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: TravelTheme.muted,
                                    ),
                                  ),
                                  if (book.cover.source.isNotEmpty)
                                    SourceLink(
                                      Reference(
                                        title: '封面来源与授权',
                                        url: book.cover.source,
                                      ),
                                      compact: true,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (model.books.isEmpty) const EmptyResult('没有找到匹配的路书。'),
          const SizedBox(height: 30),
          const Notice('旅行资料沿用原有核查日期，出发前再次确认。个人备注、清单和预算保存在本设备，可用备份文件带到其他设备。'),
          if (actions.error != null) Notice(actions.error!, warning: true),
          if (actions.message != null) Notice(actions.message!),
          const SizedBox(height: 16),
          const Text(
            'Cinna Travel Book · 旅行资料与本地记录',
            style: TextStyle(fontSize: 11, color: TravelTheme.muted),
          ),
        ],
      ),
    );
  }
}
