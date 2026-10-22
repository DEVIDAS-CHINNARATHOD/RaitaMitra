import 'models.dart';
import 'crop_names.dart';

/// Replace this provider with the production price source when verified feeds
/// are available. Demo rows are generated locally and never written to Supabase.
class DemoPriceProvider {
  static const _bands = <String, (int, int)>{
    'Tomato': (1800, 4200),
    'Paddy': (2100, 2900),
    'Maize': (1900, 2700),
    'Ragi': (2800, 4300),
    'Groundnut': (5000, 7200),
    'Ground Nut Seed': (4800, 6800),
    'Onion': (1600, 3600),
    'Potato': (1200, 2600),
    'Green Gram': (6500, 9000),
    'Bengal Gram': (5200, 6900),
    'Black Gram Dal(Urd Dal)': (7000, 9500),
    'Arecanut': (32000, 52000),
    'Arecanut(Betelnut/Supari)': (32000, 52000),
    'Coconut': (2200, 3600),
    'Garlic': (7000, 12500),
    'Ginger(Green)': (3500, 7500),
    'Turmeric': (9000, 14500),
    'Cotton': (6500, 7800),
    'Sugarcane': (280, 420),
    'Sunflower': (5500, 7200),
  };

  static List<Price> merge(
    List<Market> markets,
    Iterable<String> crops,
    List<Price> reported,
  ) {
    final reportedKeys = reported.map(_key).toSet();
    final demo = <Price>[];
    for (final market in markets) {
      for (final crop in crops) {
        if (reportedKeys.contains('${market.id}|${crop.toLowerCase()}')) {
          continue;
        }
        demo.add(_price(market, crop, daysAgo: 0));
      }
    }
    return [...reported, ...demo];
  }

  static List<Price> history(Price price, {int days = 7}) {
    final market = Market(
      price.marketId,
      price.districtId,
      price.marketName,
      null,
      null,
      false,
    );
    return List.generate(
      days,
      (index) =>
          _price(market, price.name, daysAgo: days - index - 1, current: price),
    );
  }

  static String _key(Price price) =>
      '${price.marketId}|${price.name.toLowerCase()}';

  static Price _price(
    Market market,
    String crop, {
    required int daysAgo,
    Price? current,
  }) {
    final seed = _stableHash('${market.id}|$crop');
    final (floor, ceiling) = _bands[crop] ?? (1200, 4200);
    final center = (floor + ceiling) / 2;
    final spread = (ceiling - floor) / 2;
    final marketOffset = ((seed % 17) - 8) / 100;
    final dayOffset = (((seed ~/ 17 + daysAgo * 7) % 9) - 4) / 100;
    final modal = current != null && daysAgo == 0
        ? current.modal
        : (center * (1 + marketOffset + dayOffset)).roundToDouble();
    final range = (spread * .20).roundToDouble();
    final day = DateTime.now().subtract(Duration(days: daysAgo));
    final date = DateTime(day.year, day.month, day.day);
    final previous = (center * (1 + marketOffset + dayOffset - .012))
        .roundToDouble();
    final slug = crop.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return Price({
      'market_id': market.id,
      'district_id': market.districtId,
      'market_name': market.name,
      'commodity_id': 'demo-$slug',
      'commodity_name': crop,
      'variety': 'Local',
      'grade': 'Standard',
      'report_date': date.toIso8601String().substring(0, 10),
      'modal_price': modal,
      'min_price': (modal - range).clamp(1, double.infinity),
      'max_price': modal + range,
      'previous_price': previous,
      'is_demo': true,
      'source': 'RaitaMitra demo dataset',
    });
  }

  static int _stableHash(String value) => value.codeUnits.fold<int>(
    17,
    (hash, unit) => (hash * 31 + unit) & 0x7fffffff,
  );
}

List<String> get demoCropNames => cropKannada.keys.toList(growable: false);
