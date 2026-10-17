import '../domain/travel_pdf_service.dart';
import '../../budget/domain/expense_labels.dart';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/travel_report.dart';

class BundledTravelPdfService implements TravelPdfService {
  BundledTravelPdfService(this.bundle);
  final AssetBundle bundle;
  pw.Font? _font;
  static const _forest = PdfColor.fromInt(0xff294b3d);
  static const _ink = PdfColor.fromInt(0xff26352e);
  static const _light = PdfColor.fromInt(0xfff4f1e9);
  @override
  Future<Uint8List> generate(TravelReport r, {Uint8List? mapImage}) async {
    _font ??= pw.Font.ttf(
      await bundle.load('assets/fonts/NotoSansSC-Regular.ttf'),
    );
    final doc = pw.Document(
      title: 'TravelBook · ${r.book.title}',
      author: 'Cinna',
      creator: 'Flutter travel book',
    );
    final style = pw.TextStyle(
      font: _font,
      fontSize: 9,
      color: _ink,
      lineSpacing: 2,
    );
    final widgets = <pw.Widget>[
      pw.Text(
        'TravelBook',
        style: pw.TextStyle(font: _font, fontSize: 11, color: _forest),
      ),
      pw.SizedBox(height: 14),
      pw.Text(
        r.book.title,
        style: pw.TextStyle(font: _font, fontSize: 29, color: _forest),
      ),
      pw.SizedBox(height: 6),
      pw.Text(r.book.edition),
      pw.Text(r.book.description),
      pw.SizedBox(height: 10),
      _heading('当前方案'),
      pw.Text(r.variant.label),
      if (r.variant.pending) _paragraph('办证结果未定，后续路线和住宿仍待确认。'),
      _paragraph('资料沿用原路书的核查日期；不是实时导航、价格、停车或通行许可。个人备注仅来自本设备。'),
      if (mapImage != null) ...[
        _heading('公路路线图'),
        pw.Image(pw.MemoryImage(mapImage), height: 400, fit: pw.BoxFit.contain),
        _paragraph(
          '© OpenStreetMap contributors / ODbL · OSRM 道路参考；未取得道路数据的路段保留缺口。',
        ),
      ],
      _heading(r.budget.complete ? '旅行预算' : '已填项目暂计'),
      ...r.variant.budgetWarnings.map(_paragraph),
      if (r.budget.valid) ...[
        pw.Text(
          '合计 ¥${r.budget.total.toStringAsFixed(2)} · 每人 ¥${r.budget.perPerson.toStringAsFixed(2)}',
        ),
        pw.Text('其中预备金 ¥${r.budget.reserve.toStringAsFixed(2)}（已计入合计）'),
        for (final e in r.budget.items.entries)
          pw.Text('${expenseLabel(e.key)}    ¥${e.value.toStringAsFixed(2)}'),
        if (r.budget.missing.isNotEmpty)
          _paragraph('未计入：${r.budget.missing.join('、')}。请补齐后再评估完整预算。'),
      ] else
        _paragraph('预算参数有待修正，本次不输出金额。'),
      _heading('每日行程'),
      for (final day in r.variant.days) ...[
        pw.SizedBox(height: 9),
        pw.Text(
          '${day.label} · ${day.title}',
          style: pw.TextStyle(font: _font, fontSize: 13, color: _forest),
        ),
        _paragraph(day.detail),
        for (final fact in day.facts) _paragraph('${fact.label}：${fact.value}'),
        _paragraph(
          '${day.overnight.modeLabel}：${day.overnight.title}；${day.overnight.region}；${day.overnight.address}',
        ),
        _paragraph('${day.overnight.status}。${day.overnight.note}'),
        if (day.overnight.backup != null)
          _paragraph(
            '备用住宿：${day.overnight.backup!.title}；${day.overnight.backup!.address}；${day.overnight.backup!.note}',
          ),
        for (final event in day.events) ...[
          pw.Text('${event.time} · ${event.place} → ${event.activity}'),
          for (final fact in event.facts)
            _paragraph('${fact.label}：${fact.value}'),
        ],
        for (final ref in day.navigation)
          if (ref.safeUri != null)
            pw.UrlLink(
              destination: ref.url,
              child: pw.Text(
                '${ref.title} ↗',
                style: pw.TextStyle(font: _font, color: _forest),
              ),
            ),
        if ((r.preferences.notes[day.id] ?? '').isNotEmpty) ...[
          pw.Text(
            '个人备注',
            style: pw.TextStyle(font: _font, color: _forest),
          ),
          pw.Text(r.preferences.notes[day.id]!, overflow: pw.TextOverflow.span),
          pw.SizedBox(height: 6),
        ],
      ],
      _heading('准备清单'),
      for (final task in r.book.tasks)
        _paragraph(
          '${r.preferences.checks[task.id] == true ? '[已完成]' : '[待完成]'} ${task.title} · ${task.detail}',
        ),
      if (r.book.risks.isNotEmpty) ...[
        _heading('风险与应对'),
        for (final risk in r.book.risks) ...[
          pw.Text(
            '${risk.id} · ${risk.level} · ${risk.title}',
            style: pw.TextStyle(font: _font, color: _forest),
          ),
          _paragraph('${risk.scope}；${risk.reason}'),
          _paragraph('行动：${risk.action}'),
          _paragraph('触发条件：${risk.trigger}'),
        ],
      ],
      if (r.book.permitSteps.isNotEmpty) ...[
        _heading('原路书办证流程'),
        for (final step in r.book.permitSteps)
          _paragraph('${step.date} · ${step.title} · ${step.description}'),
      ],
      _heading('资料与来源'),
      for (final note in r.book.notes) _paragraph(note),
      for (final ref in r.book.sources)
        if (ref.safeUri != null) ...[
          pw.UrlLink(
            destination: ref.url,
            child: pw.Text(
              '${ref.title} ↗',
              style: pw.TextStyle(font: _font, color: _forest),
            ),
          ),
          if (ref.description.isNotEmpty) _paragraph(ref.description),
        ],
      _paragraph(
        '照片作者和授权见应用的“事实与来源”。PDF 中的路线图数据 © OpenStreetMap contributors / ODbL。',
      ),
    ];
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        maxPages: 200,
        theme: pw.ThemeData(defaultTextStyle: style),
        header: (c) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _light)),
          ),
          child: pw.Text(
            'TravelBook · ${r.book.title}',
            style: pw.TextStyle(font: _font, fontSize: 8, color: _forest),
          ),
        ),
        footer: (c) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${c.pageNumber} / ${c.pagesCount} · 原资料日期保留',
            style: pw.TextStyle(font: _font, fontSize: 8),
          ),
        ),
        build: (_) => widgets,
      ),
    );
    return doc.save();
  }

  pw.Widget _heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
    child: pw.Text(
      text,
      style: pw.TextStyle(font: _font, fontSize: 16, color: _forest),
    ),
  );
  pw.Widget _paragraph(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.Text(text),
  );
}
