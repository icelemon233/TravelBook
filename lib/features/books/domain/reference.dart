import '../../../core/json_values.dart';

class Reference {
  const Reference({
    required this.title,
    required this.url,
    this.description = '',
  });
  factory Reference.fromJson(Json json) => Reference(
    title: json.text('title'),
    url: json.text('url'),
    description: json.text('description'),
  );
  final String title;
  final String url;
  final String description;
  Uri? get safeUri {
    final uri = Uri.tryParse(url);
    return uri != null &&
            ['https', 'http'].contains(uri.scheme) &&
            uri.host.isNotEmpty
        ? uri
        : null;
  }
}

class TravelFact {
  const TravelFact(this.label, this.value);
  factory TravelFact.fromJson(Json json) =>
      TravelFact(json.text('label'), json.text('value'));
  final String label;
  final String value;
}

class TravelPhoto {
  const TravelPhoto({
    required this.id,
    required this.asset,
    required this.title,
    required this.author,
    required this.license,
    required this.source,
    required this.licenseUrl,
    required this.generated,
  });
  factory TravelPhoto.fromJson(Json json) => TravelPhoto(
    id: json.text('id'),
    asset: json.text('asset'),
    title: json.text('title'),
    author: json.text('author'),
    license: json.text('license'),
    source: json.text('source'),
    licenseUrl: json.text('licenseUrl'),
    generated: json.flag('generated'),
  );
  final String id, asset, title, author, license, source, licenseUrl;
  final bool generated;
  String get attribution => generated ? 'AI 意境配图' : '$author · $license';
}
