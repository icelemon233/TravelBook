import 'package:flutter/services.dart';

import '../domain/trip_repository.dart';

class BundleAssetReader implements AssetReader {
  BundleAssetReader(this.bundle);
  final AssetBundle bundle;
  @override
  Future<String> read(String path) => bundle.loadString(path);
}
