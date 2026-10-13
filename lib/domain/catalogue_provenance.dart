import 'catalogue_exclusions.dart';

const sourcePriority = <String, int>{
  'label_photo': 0,
  'manufacturer': 1,
  'retailer': 2,
  'open_food_facts': 3,
};

bool hasVerifiedSource(Map<String, dynamic> row) {
  if (excludedCatalogueCodes.contains(row['code'] ?? row['barcode'])) {
    return false;
  }
  if (row['status'] != 'verified' ||
      row['catalog_batch'] == 'processed-meat-20261013' ||
      !sourcePriority.containsKey(row['source_type'])) {
    return false;
  }
  final source =
      row['source_url'] is String ? Uri.tryParse(row['source_url']) : null;
  final date = row['verified_at'] is String
      ? DateTime.tryParse(row['verified_at'])
      : null;
  return source?.scheme == 'https' &&
      source!.host.isNotEmpty &&
      source.userInfo.isEmpty &&
      date != null &&
      RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(row['verified_at']) &&
      !date.isAfter(DateTime.now().toUtc());
}
