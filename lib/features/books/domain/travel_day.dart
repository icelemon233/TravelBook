import '../../../core/json_values.dart';
import 'reference.dart';

class OvernightStop {
  OvernightStop({
    required this.mode,
    required this.title,
    required this.region,
    required this.address,
    required this.note,
    required this.status,
    required this.reason,
    this.source,
    this.backup,
  });
  factory OvernightStop.fromJson(Json json) => OvernightStop(
    mode: json.text('mode'),
    title: json.text('title'),
    region: json.text('region'),
    address: json.text('address'),
    note: json.text('note'),
    status: json.text('status'),
    reason: json.text('reason'),
    source: json['source'] == null
        ? null
        : Reference.fromJson(json.object('source')),
    backup: json['backup'] == null
        ? null
        : OvernightStop.fromJson(json.object('backup')),
  );
  final String mode, title, region, address, note, status, reason;
  final Reference? source;
  final OvernightStop? backup;
  String get modeLabel => switch (mode) {
    'car' => '车宿',
    'home' => '回家',
    'preparation' => '准备',
    _ => '酒店',
  };
  String get searchName => '$region $title';
}

class DayEvent {
  DayEvent({
    required this.time,
    required this.place,
    required this.activity,
    required List<TravelFact> facts,
  }) : facts = List.unmodifiable(facts);
  factory DayEvent.fromJson(Json json) => DayEvent(
    time: json.text('time'),
    place: json.text('place'),
    activity: json.text('activity'),
    facts: json.objects('facts').map(TravelFact.fromJson).toList(),
  );
  final String time, place, activity;
  final List<TravelFact> facts;
}

class TravelDay {
  TravelDay({
    required this.id,
    required this.number,
    required this.label,
    required this.phase,
    required this.title,
    required this.focus,
    required this.detail,
    required this.geography,
    required this.color,
    required this.overnight,
    required List<String> points,
    required List<List<String>> mapPaths,
    required List<TravelFact> facts,
    required List<Reference> navigation,
    required List<DayEvent> events,
    this.km,
    this.minutes,
  }) : points = List.unmodifiable(points),
       mapPaths = List.unmodifiable(mapPaths.map(List<String>.unmodifiable)),
       facts = List.unmodifiable(facts),
       navigation = List.unmodifiable(navigation),
       events = List.unmodifiable(events);
  factory TravelDay.fromJson(Json json) => TravelDay(
    id: json.text('id'),
    number: json.number('number')?.toInt() ?? 0,
    label: json.text('label'),
    phase: json.text('phase'),
    title: json.text('title'),
    focus: json.text('focus'),
    detail: json.text('detail'),
    geography: json.text('geography'),
    color: json.text('color', '#344d59'),
    points: json.strings('points'),
    mapPaths: json
        .array('mapPaths')
        .map((v) => (v! as List).whereType<String>().toList())
        .toList(),
    facts: json.objects('facts').map(TravelFact.fromJson).toList(),
    navigation: json.objects('navigation').map(Reference.fromJson).toList(),
    events: json.objects('events').map(DayEvent.fromJson).toList(),
    overnight: OvernightStop.fromJson(json.object('overnight')),
    km: json.number('km')?.toDouble(),
    minutes: json.number('minutes')?.toInt(),
  );
  final String id, label, phase, title, focus, detail, geography, color;
  final int number;
  final double? km;
  final int? minutes;
  final List<String> points;
  final List<List<String>> mapPaths;
  final List<TravelFact> facts;
  final List<Reference> navigation;
  final List<DayEvent> events;
  final OvernightStop overnight;
  bool get isPreparation => phase == '准备';
  String get drivingLabel => minutes == null
      ? '车程待核实'
      : minutes == 0
      ? '停车步行／休息'
      : '${minutes! ~/ 60}小时${minutes! % 60}分钟 · ${km?.toStringAsFixed(1)}km';
}
