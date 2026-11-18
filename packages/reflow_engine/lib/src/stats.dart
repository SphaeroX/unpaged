/// Median of [values]; `0` for an empty list.
double median(Iterable<double> values) {
  final sorted = values.toList()..sort();
  if (sorted.isEmpty) return 0;
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}

/// Value at [fraction] (0..1) of the sorted [values]; `0` if empty.
double percentile(Iterable<double> values, double fraction) {
  final sorted = values.toList()..sort();
  if (sorted.isEmpty) return 0;
  final index = ((sorted.length - 1) * fraction).round();
  return sorted[index];
}
