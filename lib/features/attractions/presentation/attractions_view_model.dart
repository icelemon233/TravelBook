import '../../books/domain/attraction.dart';
import '../../books/presentation/book_view_model.dart';

class AttractionsViewModel extends BookFeatureViewModel {
  AttractionsViewModel(super.bookModel, super.preferences);
  String region = '全部';
  List<String> get regions => [
    '全部',
    ...book.attractions.map((g) => g.region).toSet(),
  ];
  List<AttractionGroup> get groups => book.attractions
      .where((g) => region == '全部' || g.region == region)
      .toList(growable: false);
  int get count => groups.expand((g) => g.spots).length;
  Map<String, String> days(Attraction spot) => {
    for (final d in variant.days.where((d) => spot.dayIds.contains(d.id)))
      d.id: d.label,
  };
  void selectRegion(String value) {
    region = value;
    notifyListeners();
  }
}
