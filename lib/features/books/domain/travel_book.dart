import '../../../core/json_values.dart';
import 'attraction.dart';
import 'budget_field.dart';
import 'preparation.dart';
import 'reference.dart';
import 'return_option.dart';
import 'travel_day.dart';

class SelectorOption {
  const SelectorOption(this.id, this.label);
  factory SelectorOption.fromJson(Json json) =>
      SelectorOption(json.text('id'), json.text('label'));
  final String id, label;
}

class TripSelector {
  TripSelector(
    this.id,
    this.label,
    List<SelectorOption> options, {
    Map<String, List<String>> activeWhen = const {},
  }) : options = List.unmodifiable(options),
       activeWhen = Map.unmodifiable(
         activeWhen.map((k, v) => MapEntry(k, List<String>.unmodifiable(v))),
       );
  factory TripSelector.fromJson(Json json) => TripSelector(
    json.text('id'),
    json.text('label'),
    json.objects('options').map(SelectorOption.fromJson).toList(),
    activeWhen: json
        .object('activeWhen')
        .map((k, v) => MapEntry(k, (v! as List).whereType<String>().toList())),
  );
  final String id, label;
  final List<SelectorOption> options;
  final Map<String, List<String>> activeWhen;
  bool visibleFor(TripVariant variant) => activeWhen.entries.every(
    (e) => e.value.contains(variant.selectors[e.key]),
  );
}

class TicketPrice {
  const TicketPrice({
    required this.name,
    required this.price,
    required this.status,
    required this.note,
    required this.source,
  });
  factory TicketPrice.fromJson(Json json) => TicketPrice(
    name: json.text('name'),
    price: json.number('price')?.toDouble() ?? 0,
    status: json.text('status'),
    note: json.text('note'),
    source: Reference(title: json.text('source'), url: json.text('url')),
  );
  final String name, status, note;
  final double price;
  final Reference source;
}

class TripVariant {
  TripVariant({
    required this.id,
    required this.label,
    required this.budgetScopeId,
    required List<String> budgetWarnings,
    required Map<String, String> selectors,
    required List<TravelDay> days,
    required Map<String, double?> budgetDefaults,
    required this.pending,
    required List<TicketPrice> tickets,
  }) : selectors = Map.unmodifiable(selectors),
       days = List.unmodifiable(days),
       budgetDefaults = Map.unmodifiable(budgetDefaults),
       tickets = List.unmodifiable(tickets),
       budgetWarnings = List.unmodifiable(budgetWarnings);
  factory TripVariant.fromJson(Json json) => TripVariant(
    id: json.text('id'),
    label: json.text('label'),
    budgetScopeId: json.text('budgetScopeId', json.text('id')),
    budgetWarnings: json.strings('budgetWarnings'),
    selectors: json
        .object('selectors')
        .map((k, v) => MapEntry(k, v! as String)),
    days: json.objects('days').map(TravelDay.fromJson).toList(),
    budgetDefaults: json
        .object('budgetDefaults')
        .map((k, v) => MapEntry(k, (v as num?)?.toDouble())),
    pending: json.flag('pending'),
    tickets: json.objects('tickets').map(TicketPrice.fromJson).toList(),
  );
  final String id, label, budgetScopeId;
  final List<String> budgetWarnings;
  final Map<String, String> selectors;
  final List<TravelDay> days;
  final Map<String, double?> budgetDefaults;
  final bool pending;
  final List<TicketPrice> tickets;
  int get travelDayCount => days.where((d) => !d.isPreparation).length;
}

class TravelBook {
  TravelBook({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.edition,
    required this.description,
    this.selectionTag = '',
    required this.defaultVariantId,
    required this.coverId,
    required this.mapAsset,
    required List<String> sections,
    required List<TripSelector> selectors,
    required List<TripVariant> variants,
    required List<TravelPhoto> photos,
    required List<AttractionGroup> attractions,
    required List<BudgetField> budgetFields,
    required List<PreparationTask> tasks,
    required List<TravelRisk> risks,
    required List<PermitStep> permitSteps,
    required List<Reference> sources,
    required List<String> notes,
    required List<String?> legacyTaskIds,
    this.returnOptions,
  }) : sections = List.unmodifiable(sections),
       selectors = List.unmodifiable(selectors),
       variants = List.unmodifiable(variants),
       photos = List.unmodifiable(photos),
       attractions = List.unmodifiable(attractions),
       budgetFields = List.unmodifiable(budgetFields),
       tasks = List.unmodifiable(tasks),
       risks = List.unmodifiable(risks),
       permitSteps = List.unmodifiable(permitSteps),
       sources = List.unmodifiable(sources),
       notes = List.unmodifiable(notes),
       legacyTaskIds = List.unmodifiable(legacyTaskIds);
  factory TravelBook.fromJson(Json json) => TravelBook(
    id: json.text('id'),
    title: json.text('title'),
    subtitle: json.text('subtitle'),
    edition: json.text('edition'),
    description: json.text('description'),
    selectionTag: json.text('selectionTag'),
    defaultVariantId: json.text('defaultVariant'),
    coverId: json.text('coverId'),
    mapAsset: json.text('mapAsset'),
    sections: json.strings('sections'),
    selectors: json.objects('selectors').map(TripSelector.fromJson).toList(),
    variants: json.objects('variants').map(TripVariant.fromJson).toList(),
    photos: json.objects('photos').map(TravelPhoto.fromJson).toList(),
    attractions: json
        .objects('attractions')
        .map(AttractionGroup.fromJson)
        .toList(),
    budgetFields: json
        .objects('budgetFields')
        .map(BudgetField.fromJson)
        .toList(),
    tasks: json.objects('checks').map(PreparationTask.fromJson).toList(),
    risks: json.objects('risks').map(TravelRisk.fromJson).toList(),
    permitSteps: json.objects('permitSteps').map(PermitStep.fromJson).toList(),
    sources: json.objects('sources').map(Reference.fromJson).toList(),
    notes: json.strings('notes'),
    legacyTaskIds: json
        .array('legacyTaskIds')
        .map((v) => v as String?)
        .toList(),
    returnOptions: json['returnOptions'] == null
        ? null
        : ReturnOptions.fromJson(json.object('returnOptions')),
  );
  final String id,
      title,
      subtitle,
      edition,
      description,
      defaultVariantId,
      coverId,
      mapAsset;
  final String selectionTag;
  final List<String> sections, notes;
  final List<String?> legacyTaskIds;
  final List<TripSelector> selectors;
  final List<TripVariant> variants;
  final List<TravelPhoto> photos;
  final List<AttractionGroup> attractions;
  final List<BudgetField> budgetFields;
  final List<PreparationTask> tasks;
  final List<TravelRisk> risks;
  final List<PermitStep> permitSteps;
  final List<Reference> sources;
  final ReturnOptions? returnOptions;
  bool get isGanwan => id == 'ganwan';
  TripVariant get defaultVariant =>
      variants.firstWhere((v) => v.id == defaultVariantId);
  TripVariant variant(String? id) =>
      variants.where((v) => v.id == id).firstOrNull ?? defaultVariant;
  TripVariant select(TripVariant current, String key, String value) {
    final requested = {...current.selectors, key: value};
    return variants.firstWhere(
      (v) => requested.entries.every((e) => v.selectors[e.key] == e.value),
    );
  }

  TravelPhoto? photo(String id) => photos.where((p) => p.id == id).firstOrNull;
}

class BookSummary {
  const BookSummary({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.edition,
    required this.description,
    required this.asset,
    required this.cover,
  });
  factory BookSummary.fromJson(Json json) => BookSummary(
    id: json.text('id'),
    title: json.text('title'),
    subtitle: json.text('subtitle'),
    edition: json.text('edition'),
    description: json.text('description'),
    asset: json.text('asset'),
    cover: TravelPhoto.fromJson(json.object('cover')),
  );
  final String id, title, subtitle, edition, description, asset;
  final TravelPhoto cover;
}
