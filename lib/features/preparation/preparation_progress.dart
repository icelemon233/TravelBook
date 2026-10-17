import 'package:flutter/foundation.dart';

abstract interface class PreparationProgress implements Listenable {
  int get completed;
  int get total;
}
