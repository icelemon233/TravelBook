import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/route_map.dart';
import '../domain/map_snapshot_service.dart';

class RouteMapPainter extends CustomPainter {
  RouteMapPainter({required this.document, required this.routes, this.panel});
  final MapDocument document;
  final List<SelectedRoute> routes;
  final int? panel;
  static Color color(String value) =>
      Color(int.parse(value.replaceFirst('#', 'ff'), radix: 16));
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xfff5f2e9),
    );
    final panels = panel == null ? document.panels : [document.panels[panel!]];
    final horizontal = size.width > size.height && panels.length > 1;
    final contentHeight = size.height - 46;
    for (final e in panels.indexed) {
      final rect = horizontal
          ? Rect.fromLTWH(
              e.$1 * size.width / panels.length,
              0,
              size.width / panels.length,
              contentHeight,
            )
          : Rect.fromLTWH(
              0,
              e.$1 * contentHeight / panels.length,
              size.width,
              contentHeight / panels.length,
            );
      _panel(canvas, rect.deflate(12), e.$2);
    }
    final gaps = routes.expand((route) => route.gaps).length;
    _text(
      canvas,
      '日期：${routes.map((route) => route.label).join(' / ')}${gaps > 0 ? ' · $gaps 段道路数据缺失，未连线' : ''}',
      Offset(18, size.height - 43),
      11,
      const Color(0xff50645b),
      maxWidth: size.width - 36,
    );
    _text(
      canvas,
      '© OpenStreetMap contributors / ODbL · OSRM · WGS84 · ${document.fetched}',
      Offset(18, size.height - 21),
      11,
      const Color(0xff50645b),
      maxWidth: size.width - 36,
    );
  }

  void _panel(Canvas canvas, Rect frame, MapPanel panel) {
    final rect = Rect.fromLTRB(
      frame.left + 36,
      frame.top + 48,
      frame.right - 28,
      frame.bottom - 55,
    );
    final mid = (panel.north + panel.south) / 2 * math.pi / 180;
    final lonSpan = (panel.east - panel.west) * math.cos(mid),
        latSpan = panel.north - panel.south;
    final scale = math.min(rect.width / lonSpan, rect.height / latSpan);
    final center = rect.center;
    Offset xy(GeoPoint p) => Offset(
      center.dx +
          (p.longitude - (panel.west + panel.east) / 2) * math.cos(mid) * scale,
      center.dy - (p.latitude - (panel.south + panel.north) / 2) * scale,
    );
    Path line(List<GeoPoint> points) {
      final path = Path();
      for (final e in points.indexed) {
        final p = xy(e.$2);
        if (e.$1 == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      return path;
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(10)),
      Paint()..color = const Color(0xfffcfaf4),
    );
    _text(
      canvas,
      panel.title,
      Offset(frame.left + 18, frame.top + 13),
      20,
      const Color(0xff294b3d),
      maxWidth: frame.width - 70,
    );
    _text(
      canvas,
      'N ↑',
      Offset(frame.right - 45, frame.top + 17),
      13,
      const Color(0xff50645b),
    );
    canvas.save();
    canvas.clipRect(rect);
    final grid = Paint()
      ..color = const Color(0xffe7e7d9)
      ..strokeWidth = .7;
    for (var lon = panel.west.ceil(); lon <= panel.east; lon++) {
      final x = xy(GeoPoint(lon.toDouble(), panel.south)).dx;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), grid);
    }
    for (var lat = panel.south.ceil(); lat <= panel.north; lat++) {
      final y = xy(GeoPoint(panel.west, lat.toDouble())).dy;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grid);
    }
    for (final lake in document.lakes) {
      for (final polygon in lake.polygons) {
        final path = Path()..fillType = PathFillType.evenOdd;
        for (final ring in polygon) {
          path.addPath(line(ring)..close(), Offset.zero);
        }
        canvas.drawPath(path, Paint()..color = const Color(0xffa9ced0));
      }
    }
    for (final road in document.roads) {
      canvas.drawPath(
        line(road.points),
        Paint()
          ..color = const Color(0xffc3c9ba)
          ..strokeWidth = (road.kind == 'motorway' ? 1.2 : .65)
          ..style = PaintingStyle.stroke,
      );
    }
    // Rural connectors are actual cached polylines, never straight substitutes.
    for (final road in document.routes.values) {
      canvas.drawPath(
        line(road),
        Paint()
          ..color = const Color(0xffc7cebf)
          ..strokeWidth = .6
          ..style = PaintingStyle.stroke,
      );
    }
    for (final route in routes) {
      for (final points in route.paths) {
        canvas.drawPath(
          line(points),
          Paint()
            ..color = color(route.color)
            ..strokeWidth = 3.1
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
      }
    }
    final places = <String, MapPlace>{};
    for (final route in routes) {
      for (final place in route.places) {
        places[place.id] = place;
      }
    }
    final occupied = <Rect>[];
    for (final label in document.roadLabels) {
      final p = xy(label.point),
          box = Rect.fromLTWH(p.dx - 25, p.dy - 24, 50, 21);
      if (!rect.contains(box.topLeft) ||
          !rect.contains(box.bottomRight) ||
          occupied.any((r) => r.overlaps(box))) {
        continue;
      }
      occupied.add(box);
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(3)),
        Paint()..color = const Color(0xfffcfcf7),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(3)),
        Paint()
          ..color = const Color(0xffa7b4ae)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
      _text(
        canvas,
        label.name,
        box.topLeft + const Offset(5, 2),
        11,
        const Color(0xff60736b),
        maxWidth: 42,
      );
    }
    for (final place in places.values) {
      final p = xy(place.point);
      if (!rect.contains(p)) continue;
      canvas.drawCircle(p, 4.4, Paint()..color = const Color(0xfffcfaf4));
      canvas.drawCircle(
        p,
        4.4,
        Paint()
          ..color = const Color(0xff294b3d)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      final title = place.name,
          width = math.min(title.runes.length * 13.0 + 12, 190.0);
      final candidates = [
        Rect.fromLTWH(p.dx + 7, p.dy - 23, width, 21),
        Rect.fromLTWH(p.dx + 7, p.dy + 5, width, 21),
        Rect.fromLTWH(p.dx - width - 6, p.dy - 23, width, 21),
        Rect.fromLTWH(p.dx - width - 6, p.dy + 5, width, 21),
      ];
      final label = candidates
          .where(
            (r) =>
                rect.contains(r.topLeft) &&
                rect.contains(r.bottomRight) &&
                !occupied.any((o) => o.overlaps(r)),
          )
          .firstOrNull;
      if (label != null) {
        occupied.add(label);
        canvas.drawRRect(
          RRect.fromRectAndRadius(label, const Radius.circular(3)),
          Paint()..color = const Color(0xf0fcfaf4),
        );
        _text(
          canvas,
          title,
          label.topLeft + const Offset(4, 1),
          12,
          const Color(0xff263d31),
          maxWidth: width - 6,
        );
      }
    }
    canvas.restore();
    _text(
      canvas,
      '彩线为道路参考 · 不含实时路况与通行许可',
      Offset(frame.left + 16, frame.bottom - 25),
      11,
      const Color(0xff66766b),
      maxWidth: frame.width - 24,
    );
  }

  void _text(
    Canvas canvas,
    String value,
    Offset offset,
    double size,
    Color color, {
    double? maxWidth,
  }) {
    final text = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: size,
          color: color,
          height: 1.25,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? 220);
    text.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(RouteMapPainter old) =>
      old.document != document || old.routes != routes || old.panel != panel;
}

class MapImageRenderer implements MapSnapshotService {
  const MapImageRenderer();
  @override
  Future<Uint8List> render(
    MapDocument map,
    List<SelectedRoute> routes, {
    int? panel,
  }) async {
    final size = Size(800, panel == null && map.panels.length > 1 ? 550 : 525),
        recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(2);
    RouteMapPainter(
      document: map,
      routes: routes,
      panel: panel,
    ).paint(canvas, size);
    final picture = recorder.endRecording(),
        image = await picture.toImage(
          (size.width * 2).toInt(),
          (size.height * 2).toInt(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    if (bytes == null) throw StateError('地图图像生成失败');
    return bytes.buffer.asUint8List();
  }
}
