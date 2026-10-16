import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final source = img.decodePng(
    File('assets/images/tibet/generated/xinglian-tibet-icon.png')
        .readAsBytesSync(),
  );
  if (source == null) throw StateError('Original travel icon is unreadable');
  void write(String path, int size) {
    final resized = img.copyResize(
      source,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
    );
    final rgb = img.Image(width: size, height: size, numChannels: 3);
    img.fill(rgb, color: img.ColorRgb8(7, 37, 77));
    img.compositeImage(rgb, resized);
    final file = File(path)..parent.createSync(recursive: true);
    file.writeAsBytesSync(img.encodePng(rgb));
  }

  for (final e in {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  }.entries) {
    write('android/app/src/main/res/mipmap-${e.key}/ic_launcher.png', e.value);
  }
  final contents = jsonDecode(
    File('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  for (final value in contents['images'] as List) {
    final icon = value as Map<String, dynamic>;
    final filename = icon['filename'] as String?;
    if (filename == null) continue;
    final logical = double.parse((icon['size'] as String).split('x').first),
        scale = double.parse((icon['scale'] as String).replaceAll('x', ''));
    write(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/$filename',
      (logical * scale).round(),
    );
  }
  write('web/favicon.png', 32);
  for (final size in [192, 512]) {
    write('web/icons/Icon-$size.png', size);
    write('web/icons/Icon-maskable-$size.png', size);
  }
  stdout.writeln(
    'Existing mountain/lake brand icon generated for Android, iOS and Web.',
  );
}
