class EnergyCalculator {
  const EnergyCalculator();
  double? range({
    required double? range,
    required double? start,
    required double? reserve,
    required double? derate,
  }) {
    if ([range, start, reserve, derate].any((v) => v == null || !v.isFinite)) {
      return null;
    }
    if (range! <= 0 ||
        range > 2000 ||
        start! < 0 ||
        start > 100 ||
        reserve! < 0 ||
        reserve > 100 ||
        derate! < 0 ||
        derate > 90 ||
        start <= reserve) {
      return null;
    }
    return range * (start - reserve) / 100 * (1 - derate / 100);
  }

  double? morning({
    required double? battery,
    required double? soc,
    required double? use,
  }) {
    if ([battery, soc, use].any((v) => v == null || !v.isFinite)) return null;
    if (battery! <= 0 || soc! < 0 || soc > 100 || use! < 0) return null;
    return soc - use / battery * 100;
  }
}
