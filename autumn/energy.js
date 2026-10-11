export function estimateRange(range, start, reserve, derate) {
  if (![range,start,reserve,derate].every(Number.isFinite) || range <= 0 || range > 2000 || start < 0 || start > 100 || reserve < 0 || reserve > 100 || derate < 0 || derate > 90 || start <= reserve) return null;
  return range * (start-reserve) / 100 * (1-derate/100);
}
export function estimateMorning(battery, soc, use) {
  if (![battery,soc,use].every(Number.isFinite) || battery <= 0 || soc < 0 || soc > 100 || use < 0) return null;
  return soc - use / battery * 100;
}
