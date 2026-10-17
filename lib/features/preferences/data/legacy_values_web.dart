import 'package:web/web.dart' as web;

Map<String, String?> readLegacyValues() => {
  for (final key in [
    'cinna-ganwan-v1',
    'tibet-checklist-personal-v2',
    'tibet-checklist',
  ])
    key: web.window.localStorage.getItem(key),
};
