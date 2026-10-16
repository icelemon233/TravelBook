import '../../books/presentation/book_view_model.dart';
import '../domain/energy_calculator.dart';

class EnergyViewModel extends BookFeatureViewModel {
  EnergyViewModel(super.bookModel, super.preferences);
  static const defaults = {
    'range': '300',
    'start-soc': '90',
    'reserve-soc': '20',
    'derate': '15',
    'battery': '',
    'bed-soc': '80',
    'night-use': '',
  };
  final calculator = const EnergyCalculator();
  Map<String, String> get values => {
    ...defaults,
    ...preferences.snapshot.value.forBook(book.id).energy,
  };
  double? value(String id) => double.tryParse(values[id] ?? '');
  double? get distance => calculator.range(
    range: value('range'),
    start: value('start-soc'),
    reserve: value('reserve-soc'),
    derate: value('derate'),
  );
  double? get morning => calculator.morning(
    battery: value('battery'),
    soc: value('bed-soc'),
    use: value('night-use'),
  );
  bool get missingNight =>
      (values['battery'] ?? '').isEmpty || (values['night-use'] ?? '').isEmpty;
  bool get nightWarning => !missingNight && (morning == null || morning! < 20);
  String get rangeLabel => distance == null
      ? '请填写有效数值，出发SOC需高于抵达保留SOC。'
      : '粗估可规划 ${distance!.floor()} km';
  String get morningLabel => missingNight
      ? '填写电池容量与整夜总耗电后计算。'
      : morning == null
      ? '请检查电池容量、睡前SOC与整夜总耗电。'
      : morning! < 0
      ? '预计夜耗超过睡前可用电量，请先补电或改住酒店。'
      : '早晨粗估剩余 ${morning!.toStringAsFixed(1)}%${morning! < 20 ? '，需重新安排补能或过夜。' : '；还需核对次日及备用站路程。'}';
  Future<void> edit(String id, String value) => preferences.updateBook(
    book.id,
    (p) => p.copyWith(energy: {...p.energy, id: value}),
  );
}
