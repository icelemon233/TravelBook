import 'dart:typed_data';
import 'dart:ui';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'file_actions.dart';

class PlatformFileActions implements FileActions {
  @override
  Future<void> openLink(Uri uri) async {
    if (!['http', 'https'].contains(uri.scheme) || uri.host.isEmpty) {
      throw const FormatException('链接地址不受支持');
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('无法打开链接，请复制地址后在浏览器打开。');
    }
  }

  @override
  Future<void> save(
    Uint8List bytes,
    String name,
    String mime, {
    Rect? origin,
  }) async {
    final file = XFile.fromData(bytes, mimeType: mime, name: name);
    if (kIsWeb) {
      await file.saveTo(name);
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: [name],
        sharePositionOrigin: origin,
        downloadFallbackEnabled: true,
      ),
    );
  }

  @override
  Future<String?> pickBackup({required int maxBytes}) async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'TravelBook 备份',
          extensions: ['json'],
          mimeTypes: ['application/json'],
          uniformTypeIdentifiers: ['public.json'],
        ),
      ],
    );
    if (file == null) return null;
    if (await file.length() > maxBytes) {
      throw FormatException('备份文件超过${maxBytes ~/ (1024 * 1024)} MiB');
    }
    return file.readAsString();
  }

  @override
  Future<void> printPdf(Uint8List bytes, String name) async {
    await Printing.layoutPdf(onLayout: (_) => bytes, name: name);
  }
}
