import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/ui/page_components.dart';
import '../features/export/backup_dialogs.dart';
import '../features/books/presentation/book_view_model.dart';
import '../features/export/export_actions.dart';
import '../features/preferences/preferences_status.dart';
import '../core/ui/travel_theme.dart';

class SectionDestination {
  const SectionDestination(this.label, this.icon);
  final String label;
  final IconData icon;
}

const sections = <String, SectionDestination>{
  'overview': SectionDestination('旅程概览', Icons.menu_book_outlined),
  'itinerary': SectionDestination('每日行程', Icons.route_outlined),
  'map': SectionDestination('公路地图', Icons.map_outlined),
  'attractions': SectionDestination('旅途景点', Icons.landscape_outlined),
  'stays': SectionDestination('床车与酒店', Icons.bed_outlined),
  'budget': SectionDestination('旅行账本', Icons.account_balance_wallet_outlined),
  'returns': SectionDestination('返程对比', Icons.compare_arrows),
  'energy': SectionDestination('电量与补能', Icons.ev_station_outlined),
  'checklist': SectionDestination('出发清单', Icons.fact_check_outlined),
  'risks': SectionDestination('风险应对', Icons.warning_amber),
  'permits': SectionDestination('办证与分流', Icons.badge_outlined),
  'sources': SectionDestination('事实与来源', Icons.library_books_outlined),
};

class BookShell extends StatelessWidget {
  const BookShell({super.key, required this.section, required this.child});
  final String section;
  final Widget child;
  void _go(BuildContext context, BookViewModel model, String section) =>
      context.go('/book/${model.book.id}/$section');
  @override
  Widget build(BuildContext context) {
    final model = context.watch<BookViewModel>(),
        actions = context.watch<ExportActions>(),
        status = context.watch<PreferencesStatus>();
    final wide = MediaQuery.sizeOf(context).width >= 1000, book = model.book;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回路书目录',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.auto_stories_outlined),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Text(
              'CINNA / TRAVEL BOOK',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.2,
                color: TravelTheme.muted,
              ),
            ),
          ],
        ),
        actions: [
          if (actions.busy)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox.square(
                dimension: 19,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (!wide)
            IconButton(
              tooltip: '更改路线方案',
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => ChangeNotifierProvider.value(
                  value: model,
                  child: const _SelectorSheet(),
                ),
              ),
              icon: const Icon(Icons.tune),
            ),
          Builder(
            builder: (anchor) => PopupMenuButton<String>(
              tooltip: '导出与备份',
              enabled: !actions.busy,
              onSelected: (value) => unawaited(_action(anchor, actions, value)),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'pdf', child: Text('导出完整路书 PDF')),
                const PopupMenuItem(value: 'print', child: Text('打印路书')),
                const PopupMenuItem(value: 'backup', child: Text('导出本地备份')),
                const PopupMenuItem(value: 'import', child: Text('导入备份文件')),
                const PopupMenuItem(value: 'paste', child: Text('粘贴备份内容')),
                if (status.state.recoveryRaw != null)
                  const PopupMenuItem(
                    value: 'recovery',
                    child: Text('导出原始恢复副本'),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (wide)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(25, 12, 25, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: TravelTheme.line)),
              ),
              child: const _SelectorBar(),
            ),
          if (!wide)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: TravelTheme.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      model.selectionCaption,
                      style: const TextStyle(
                        fontSize: 11,
                        color: TravelTheme.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    status.label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: TravelTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          if (status.state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Notice(status.state.error!, warning: true),
            ),
          if (actions.error != null || actions.message != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Notice(
                      actions.error ?? actions.message!,
                      warning: actions.error != null,
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭提示',
                    onPressed: actions.clearMessage,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Row(
              children: [
                if (wide)
                  SizedBox(
                    width: 215,
                    child: _SideNavigation(model: model, section: section),
                  ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: switch (section) {
                'overview' => 0,
                'itinerary' => 1,
                'map' => 2,
                'budget' => 3,
                _ => 4,
              },
              onDestinationSelected: (index) {
                if (index < 4) {
                  _go(
                    context,
                    model,
                    ['overview', 'itinerary', 'map', 'budget'][index],
                  );
                } else {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (sheet) => SafeArea(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final id in book.sections)
                            ListTile(
                              leading: Icon(sections[id]!.icon),
                              title: Text(sections[id]!.label),
                              selected: section == id,
                              onTap: () {
                                Navigator.pop(sheet);
                                _go(context, model, id);
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  label: '概览',
                ),
                NavigationDestination(
                  icon: Icon(Icons.route_outlined),
                  label: '行程',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  label: '地图',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  label: '预算',
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_horiz),
                  label: '更多',
                ),
              ],
            ),
    );
  }

  Future<void> _action(
    BuildContext context,
    ExportActions actions,
    String value,
  ) async {
    switch (value) {
      case 'pdf':
        await actions.exportPdf(origin: shareOrigin(context));
      case 'print':
        await actions.exportPdf(print: true, origin: shareOrigin(context));
      case 'backup':
        await actions.exportBackup(origin: shareOrigin(context));
      case 'recovery':
        await actions.exportRecovery(origin: shareOrigin(context));
      case 'import':
        await requestBackupImport(context, actions);
      case 'paste':
        await requestBackupPaste(context, actions);
    }
  }
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({required this.model, required this.section});
  final BookViewModel model;
  final String section;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(right: BorderSide(color: TravelTheme.line)),
    ),
    child: ListView(
      padding: const EdgeInsets.all(13),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 15, 8, 12),
          child: Text(
            '路书目录',
            style: TextStyle(
              fontSize: 11,
              color: TravelTheme.muted,
              letterSpacing: 1,
            ),
          ),
        ),
        for (final id in model.book.sections)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              dense: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              selected: section == id,
              selectedTileColor: TravelTheme.forest.withValues(alpha: .09),
              leading: Icon(sections[id]!.icon, size: 19),
              title: Text(
                sections[id]!.label,
                style: const TextStyle(fontSize: 13),
              ),
              onTap: () => context.go('/book/${model.book.id}/$id'),
            ),
          ),
        const Divider(),
        TextButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.swap_horiz, size: 18),
          label: const Text('切换路书'),
        ),
        Consumer<PreferencesStatus>(
          builder: (_, status, _) => Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              status.label,
              style: const TextStyle(fontSize: 10, color: TravelTheme.muted),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SelectorBar extends StatelessWidget {
  const _SelectorBar();
  @override
  Widget build(BuildContext context) {
    final model = context.watch<BookViewModel>();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final selector in model.selectors)
          SelectionField(
            label: selector.label,
            value: model.variant.selectors[selector.id]!,
            options: {
              for (final option in selector.options) option.id: option.label,
            },
            onChanged: (value) => unawaited(model.select(selector.id, value)),
          ),
        if (model.book.selectionTag.isNotEmpty)
          Chip(label: Text(model.book.selectionTag)),
      ],
    );
  }
}

class _SelectorSheet extends StatelessWidget {
  const _SelectorSheet();
  @override
  Widget build(BuildContext context) {
    final model = context.watch<BookViewModel>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('更改路线方案', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            for (final selector in model.selectors) ...[
              SelectionField(
                width: MediaQuery.sizeOf(context).width - 48,
                label: selector.label,
                value: model.variant.selectors[selector.id]!,
                options: {
                  for (final option in selector.options)
                    option.id: option.label,
                },
                onChanged: (value) =>
                    unawaited(model.select(selector.id, value)),
              ),
              const SizedBox(height: 16),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('完成'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
