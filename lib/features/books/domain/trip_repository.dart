import '../../map/domain/route_map.dart';
import 'travel_book.dart';

abstract interface class TripRepository {
  Future<List<BookSummary>> catalog();
  Future<TravelBook> book(String id);
  Future<MapDocument> map(String id);
}

abstract interface class AssetReader {
  Future<String> read(String path);
}
