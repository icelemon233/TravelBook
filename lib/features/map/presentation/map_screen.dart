import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/travel_theme.dart';
import '../../../core/ui/page_components.dart';
import '../../books/book_components.dart';
import '../../books/domain/reference.dart';
import '../../export/export_actions.dart';
import 'map_view_model.dart';
import 'route_map_painter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.initialDay});
  final String? initialDay;
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _transform = TransformationController();
  @override
  void initState() {
    super.initState();
    _syncRoute();
  }

  @override
  void didUpdateWidget(MapScreen old) {
    super.didUpdateWidget(old);
    if (old.initialDay != widget.initialDay) _syncRoute();
  }

  void _syncRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final model = context.read<MapViewModel>();
        model.selectDay(widget.initialDay);
        unawaited(model.load());
      }
    });
  }

  void _selectDay(String? day) {
    final bookId = context.read<MapViewModel>().book.id;
    context.go(
      Uri(
        path: '/book/$bookId/map',
        queryParameters: day == null ? null : {'day': day},
      ).toString(),
    );
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MapViewModel>(),
        actions = context.watch<ExportActions>();
    final map = model.document, routes = model.routes;
    return TravelPage(
      children: [
        PageHeading(
          number: '03',
          title: '公路路线图',
          description: '随当前行程版本和日期切换。地图与道路数据随应用保存，查看时不连接外部地图服务。',
          action: Builder(
            builder: (context) => OutlinedButton.icon(
              onPressed: actions.busy || map == null
                  ? null
                  : () => unawaited(
                      actions.exportMap(origin: shareOrigin(context)),
                    ),
              icon: const Icon(Icons.download_outlined),
              label: const Text('保存当前地图'),
            ),
          ),
        ),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            ChoiceChip(
              label: const Text('全部日期'),
              selected: model.selectedDay == null,
              onSelected: (_) => _selectDay(null),
            ),
            ...model.variant.days
                .where((d) => !d.isPreparation)
                .map(
                  (day) => ChoiceChip(
                    label: Text(day.label),
                    avatar: CircleAvatar(
                      backgroundColor: RouteMapPainter.color(day.color),
                      radius: 4,
                    ),
                    selected: model.selectedDay == day.id,
                    onSelected: (_) => _selectDay(day.id),
                  ),
                ),
          ],
        ),
        const SizedBox(height: 14),
        if (map != null && map.panels.length > 1)
          Wrap(
            spacing: 8,
            runSpacing: 7,
            children: [
              ChoiceChip(
                label: const Text('双图'),
                selected: model.panel == null,
                onSelected: (_) => model.selectPanel(null),
              ),
              ...map.panels.indexed.map(
                (p) => ChoiceChip(
                  label: Text(p.$2.title),
                  selected: model.panel == p.$1,
                  onSelected: (_) => model.selectPanel(p.$1),
                ),
              ),
            ],
          ),
        const SizedBox(height: 14),
        if (model.loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (model.error != null)
          PaperCard(
            child: Column(
              children: [
                Notice(model.error!, warning: true),
                FilledButton(
                  onPressed: () => unawaited(model.load()),
                  child: const Text('重新加载地图'),
                ),
              ],
            ),
          ),
        if (map != null) ...[
          PaperCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        '拖动／双指缩放',
                        style: TextStyle(
                          fontSize: 12,
                          color: TravelTheme.muted,
                        ),
                      ),
                      IconButton(
                        tooltip: '放大地图',
                        onPressed: () =>
                            _transform.value = Matrix4.diagonal3Values(2, 2, 1),
                        icon: const Icon(Icons.zoom_in),
                      ),
                      TextButton.icon(
                        onPressed: () => _transform.value = Matrix4.identity(),
                        icon: const Icon(Icons.fit_screen),
                        label: const Text('重置视图'),
                      ),
                    ],
                  ),
                ),
                LayoutBuilder(
                  builder: (context, box) {
                    final height =
                        box.maxWidth < 650 &&
                            model.panel == null &&
                            map.panels.length > 1
                        ? box.maxWidth * 1.6
                        : box.maxWidth * .68;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: height.clamp(260, 900),
                        width: double.infinity,
                        child: InteractiveViewer(
                          transformationController: _transform,
                          maxScale: 6,
                          boundaryMargin: const EdgeInsets.all(60),
                          child: Semantics(
                            label:
                                '公路路线图。当前日期：${routes.map((r) => r.label).join('、')}。缺少道路的路段不连线。',
                            child: RepaintBoundary(
                              child: CustomPaint(
                                isComplex: true,
                                size: Size(
                                  box.maxWidth,
                                  height.clamp(260, 900),
                                ),
                                painter: RouteMapPainter(
                                  document: map,
                                  routes: routes,
                                  panel: model.panel,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          if (model.gaps.isNotEmpty)
            Notice(
              '以下路段尚未取得完整道路数据，地图保留缺口：${model.gaps.join('；')}。',
              warning: true,
            ),
          if (model.variant.pending)
            const Notice('办证结果未定的后续日期不绘制连续路线。', warning: true),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前地图涉及地点',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: routes
                      .expand((r) => r.places)
                      .map((p) => p.name)
                      .toSet()
                      .map(
                        (name) => Chip(
                          label: Text(name),
                          avatar: const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          Notice(
            '数据获取日期：${map.fetched} · WGS84。彩线是道路参考，不是实时导航。节点不代表已确认的景区入口、停车场、充电站或车宿许可。',
          ),
          const SourceLink(
            Reference(
              title: '© OpenStreetMap contributors · ODbL',
              url: 'https://www.openstreetmap.org/copyright',
            ),
          ),
          const SourceLink(
            Reference(title: 'OSRM 道路路线服务', url: 'https://project-osrm.org/'),
          ),
        ],
      ],
    );
  }
}
