import 'dart:typed_data';
import 'dart:ui';

abstract interface class FileActions {
  Future<void> openLink(Uri uri);
  Future<void> save(Uint8List bytes, String name, String mime, {Rect? origin});
  Future<String?> pickBackup();
  Future<void> printPdf(Uint8List bytes, String name);
}
