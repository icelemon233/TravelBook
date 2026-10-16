typedef Json = Map<String, Object?>;

Json jsonObject(Object? value) {
  if (value is! Map) throw const FormatException('Expected a JSON object');
  return Map<String, Object?>.from(value);
}

extension JsonValues on Json {
  String text(String key, [String fallback = '']) =>
      this[key] is String ? this[key]! as String : fallback;
  bool flag(String key) => this[key] == true;
  num? number(String key) => this[key] is num ? this[key]! as num : null;
  List<Object?> array(String key) =>
      this[key] is List ? List<Object?>.from(this[key]! as List) : const [];
  List<String> strings(String key) =>
      array(key).whereType<String>().toList(growable: false);
  List<Json> objects(String key) =>
      array(key).map(jsonObject).toList(growable: false);
  Json object(String key) =>
      this[key] == null ? const {} : jsonObject(this[key]);
}
