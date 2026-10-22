import 'package:intl/intl.dart';

typedef Json = Map<String, dynamic>;
String money(num value) => '₹${NumberFormat('#,##0', 'en_IN').format(value)}';
String dayLabel(DateTime value) => DateFormat('d MMM yyyy').format(value);
String dateOnly(DateTime value) => DateFormat('yyyy-MM-dd').format(value);
double? number(dynamic value) =>
    value == null ? null : double.tryParse(value.toString());

class Market {
  Market(
    this.id,
    this.districtId,
    this.name,
    this.latitude,
    this.longitude,
    this.verified,
  );
  factory Market.fromJson(Json j) => Market(
    j['id'],
    j['district_id'],
    j['name'],
    number(j['latitude']),
    number(j['longitude']),
    j['verified'] == true,
  );
  final String id, districtId, name;
  final double? latitude, longitude;
  final bool verified;
}

class Price {
  Price(this.json);
  final Json json;
  String get marketId => json['market_id'];
  String get commodityId => json['commodity_id'];
  String get name => json['commodity_name'] ?? '';
  String get marketName => json['market_name'] ?? '';
  String get districtId => json['district_id'] ?? '';
  String get variety => json['variety'] ?? '';
  String get grade => json['grade'] ?? '';
  DateTime get date => DateTime.parse(json['report_date']);
  double get modal => number(json['modal_price']) ?? 0;
  double? get min => number(json['min_price']);
  double? get max => number(json['max_price']);
  double? get previous => number(json['previous_price']);
  double? get change => previous == null || previous == 0
      ? null
      : (modal - previous!) / previous! * 100;
  bool get old => DateTime.now().difference(date).inDays > 3;
  bool get isDemo => json['is_demo'] == true;
}

class FarmCrop {
  FarmCrop(this.json);
  final Json json;
  String get id => json['id'];
  String get name => json['commodity_name'];
  String get variety => json['variety'] ?? '';
  double? get quantity => number(json['quantity']);
  DateTime get planted => DateTime.parse(json['planting_date']);
  DateTime? get harvest => DateTime.tryParse(json['harvest_date'] ?? '');
  String? get marketId => json['market_id'];
  String get notes => json['notes'] ?? '';
}

class CachedSnapshot {
  CachedSnapshot(this.data, this.savedAt, {this.offline = false});
  final dynamic data;
  final DateTime savedAt;
  final bool offline;
}
