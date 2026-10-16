import '../../../core/json_values.dart';
import 'reference.dart';

class Attraction {
  Attraction({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.source,
    required List<String> dayIds,
  }) : dayIds = List.unmodifiable(dayIds);
  factory Attraction.fromJson(Json json) => Attraction(
    id: json.text('id'),
    name: json.text('name'),
    type: json.text('type'),
    description: json.text('description'),
    source: Reference.fromJson(json.object('source')),
    dayIds: json.strings('dayIds'),
  );
  final String id, name, type, description;
  final Reference source;
  final List<String> dayIds;
}

class AttractionGroup {
  AttractionGroup({
    required this.id,
    required this.title,
    required this.region,
    required this.photoId,
    required this.caption,
    required List<Attraction> spots,
  }) : spots = List.unmodifiable(spots);
  factory AttractionGroup.fromJson(Json json) => AttractionGroup(
    id: json.text('id'),
    title: json.text('title'),
    region: json.text('region'),
    photoId: json.text('photo'),
    caption: json.text('caption'),
    spots: json.objects('spots').map(Attraction.fromJson).toList(),
  );
  final String id, title, region, photoId, caption;
  final List<Attraction> spots;
}
