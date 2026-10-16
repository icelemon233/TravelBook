import '../../../core/json_values.dart';

class ReturnLeg {
  const ReturnLeg({
    required this.id,
    required this.from,
    required this.to,
    required this.fromRegion,
    required this.toRegion,
    required this.roads,
    required this.url,
    required this.km,
    required this.minutes,
    required this.tolls,
  });
  factory ReturnLeg.fromJson(Json json) => ReturnLeg(
    id: json.text('id'),
    from: json.text('fromLabel'),
    to: json.text('toLabel'),
    fromRegion: json.text('fromRegion'),
    toRegion: json.text('toRegion'),
    roads: json.text('roads'),
    url: json.text('url'),
    km: json.number('km')!.toDouble(),
    minutes: json.number('minutes')!.toInt(),
    tolls: json.number('tolls')!.toDouble(),
  );
  final String id, from, to, fromRegion, toRegion, roads, url;
  final double km, tolls;
  final int minutes;
}

class ReturnOption {
  ReturnOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.summary,
    required this.note,
    required List<String> legIds,
    required List<String> nightModes,
    required this.directKm,
    required this.directUrl,
  }) : legIds = List.unmodifiable(legIds),
       nightModes = List.unmodifiable(nightModes);
  factory ReturnOption.fromJson(Json json) => ReturnOption(
    id: json.text('id'),
    title: json.text('title'),
    subtitle: json.text('subtitle'),
    route: json.text('route'),
    summary: json.text('summary'),
    note: json.text('note'),
    legIds: json.strings('legIds'),
    nightModes: json.strings('nightModes'),
    directKm: json.object('direct').number('km')?.toDouble(),
    directUrl: json.object('direct').text('url'),
  );
  final String id, title, subtitle, route, summary, note, directUrl;
  final double? directKm;
  final List<String> legIds, nightModes;
}

class ReturnOptions {
  ReturnOptions({
    required this.checkedDate,
    required this.note,
    required List<ReturnOption> options,
    required List<ReturnLeg> legs,
  }) : options = List.unmodifiable(options),
       legs = List.unmodifiable(legs);
  factory ReturnOptions.fromJson(Json json) => ReturnOptions(
    checkedDate: json.text('checkedDate'),
    note: json.text('note'),
    options: json.objects('options').map(ReturnOption.fromJson).toList(),
    legs: json.objects('legs').map(ReturnLeg.fromJson).toList(),
  );
  final String checkedDate, note;
  final List<ReturnOption> options;
  final List<ReturnLeg> legs;
  List<ReturnLeg> legsFor(ReturnOption option) => option.legIds
      .map((id) => legs.firstWhere((leg) => leg.id == id))
      .toList(growable: false);
}
