import 'dart:typed_data';

import 'travel_report.dart';

abstract interface class TravelPdfService {
  Future<Uint8List> generate(TravelReport report, {Uint8List? mapImage});
}
