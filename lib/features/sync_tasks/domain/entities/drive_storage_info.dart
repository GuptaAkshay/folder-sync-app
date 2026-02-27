/// Represents Google Drive storage quota information.
///
/// Values are in gigabytes for display convenience.
class DriveStorageInfo {
  const DriveStorageInfo({required this.usedGb, required this.totalGb});

  /// Storage used in GB.
  final double usedGb;

  /// Total storage limit in GB.
  final double totalGb;

  /// Usage as a 0.0–1.0 fraction.
  double get usagePercent =>
      totalGb > 0 ? (usedGb / totalGb).clamp(0.0, 1.0) : 0.0;

  @override
  String toString() =>
      'DriveStorageInfo(used: ${usedGb.toStringAsFixed(2)} GB, '
      'total: ${totalGb.toStringAsFixed(0)} GB)';
}
