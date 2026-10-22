import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../state.dart';
import '../data/models.dart';
import '../data/price_outlook.dart';
import '../data/demo_price_provider.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key, required this.state});
  final AppState state;
  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  String search = '', district = '';
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final list = s.markets
        .where(
          (m) =>
              (district.isEmpty || m.districtId == district) &&
              (m.name.toLowerCase().contains(search.toLowerCase()) ||
                  s
                      .districtName(m.districtId)
                      .toLowerCase()
                      .contains(search.toLowerCase())),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const ScenicAppBarBackground(),
        title: Text(s.t('Markets', 'ಮಾರುಕಟ್ಟೆಗಳು')),
        actions: [
          IconButton(
            tooltip: 'Compare prices',
            onPressed: () => openPage(context, CompareScreen(state: s)),
            icon: const Icon(Icons.compare_arrows),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          Text(
            s.t('Across Karnataka.', 'ಕರ್ನಾಟಕದಾದ್ಯಂತ.'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            '${s.districts.length} districts · ${s.markets.length} listed mandis',
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 22),
          TextField(
            onChanged: (v) => setState(() => search = v),
            decoration: InputDecoration(
              hintText: s.t(
                'Search mandi or district',
                'ಮಾರುಕಟ್ಟೆ ಅಥವಾ ಜಿಲ್ಲೆ ಹುಡುಕಿ',
              ),
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: district,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'District'),
            items: [
              const DropdownMenuItem(value: '', child: Text('All Karnataka')),
              ...s.districts.map(
                (d) => DropdownMenuItem<String>(
                  value: d['id'],
                  child: Text(
                    '${d['name']} (${s.markets.where((m) => m.districtId == d['id']).length})',
                  ),
                ),
              ),
            ],
            onChanged: (v) => setState(() => district = v ?? ''),
          ),
          const SizedBox(height: 20),
          if (list.isEmpty)
            const EmptyPanel(
              icon: Icons.search_off,
              title: 'No markets found',
              body: 'Try another district or spelling.',
            ),
          ...list.map((m) {
            final count = s.prices.where((p) => p.marketId == m.id).length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: paleBlue,
                    child: Icon(
                      Icons.storefront_outlined,
                      color: accentBlue,
                      size: 21,
                    ),
                  ),
                  title: Text(
                    m.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${s.districtName(m.districtId)}\n${count > 0 ? '$count available price reports' : 'No price reports loaded'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: muted,
                      height: 1.6,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () =>
                      openPage(context, MarketScreen(state: s, market: m)),
                ),
              ),
            );
          }),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Directory entries are supplied by the project team. Market and sub-yard status is awaiting verification.',
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key, required this.state, required this.market});
  final AppState state;
  final Market market;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final prices = state.prices
          .where((p) => p.marketId == market.id)
          .toList();
      return Scaffold(
        appBar: AppBar(
          flexibleSpace: const ScenicAppBarBackground(),
          title: Text(market.name),
        ),
        body: PageBody(
          children: [
            Text(
              state.districtName(market.districtId),
              style: const TextStyle(color: muted),
            ),
            if (prices.any((p) => p.isDemo)) ...[
              const SizedBox(height: 12),
              const Notice(
                'Sample market report · Prices and report dates are simulated examples, not live mandi quotes.',
              ),
            ],
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await state.saveProfile(
                    newName: state.name,
                    district: market.districtId,
                    market: market.id,
                  );
                  if (context.mounted) {
                    toast(context, 'Preferred mandi updated.');
                  }
                } catch (_) {
                  if (context.mounted) {
                    toast(context, 'Could not save this preference.');
                  }
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                state.marketId == market.id
                    ? 'Your preferred mandi'
                    : 'Use as my preferred mandi',
              ),
            ),
            SectionLabel(
              'Available prices',
              action: state.busy ? 'Checking…' : 'Refresh',
              onTap: state.busy ? null : () => state.refresh(market.id),
            ),
            if (prices.isEmpty)
              EmptyPanel(
                icon: Icons.receipt_long_outlined,
                title: 'No reports loaded',
                body:
                    'This market remains in the directory even when the source has no matching reports.',
                action: 'Check source',
                onAction: state.busy ? null : () => state.refresh(market.id),
              )
            else
              Card(
                child: Column(
                  children: prices
                      .map(
                        (p) => PriceTile(
                          p,
                          onTap: () => openPage(
                            context,
                            PriceScreen(state: state, price: p),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 20),
            if (state.message.isNotEmpty) Notice(state.message),
            const SizedBox(height: 12),
            Notice(
              market.verified
                  ? 'Market location verified.'
                  : 'Coordinates are awaiting verification. A distance estimate is not available.',
            ),
          ],
        ),
      );
    },
  );
}

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key, required this.state, this.initial});
  final AppState state;
  final Price? initial;
  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  String? commodity, variety;
  bool districtOnly = false;
  @override
  void initState() {
    super.initState();
    commodity = widget.initial?.name;
    variety = widget.initial == null
        ? null
        : '${widget.initial!.variety} / ${widget.initial!.grade}';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final names = s.prices.map((p) => p.name).toSet().toList()..sort();
    final variants =
        s.prices
            .where((p) => p.name == commodity)
            .map((p) => '${p.variety} / ${p.grade}')
            .toSet()
            .toList()
          ..sort();
    final results =
        s.prices
            .where(
              (p) =>
                  p.name == commodity &&
                  (variety == null || '${p.variety} / ${p.grade}' == variety) &&
                  (!districtOnly || p.districtId == s.districtId),
            )
            .toList()
          ..sort((a, b) => b.modal.compareTo(a.modal));
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const ScenicAppBarBackground(),
        title: const Text('Compare mandis'),
      ),
      body: PageBody(
        children: [
          Text(
            'Find your options.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Compare reported prices for the same variety and grade.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 22),
          DropdownButtonFormField<String>(
            initialValue: commodity,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Commodity'),
            items: names
                .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                .toList(),
            onChanged: (v) => setState(() {
              commodity = v;
              variety = null;
            }),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: ValueKey(commodity),
            initialValue: variety,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Variety / grade'),
            items: variants
                .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                .toList(),
            onChanged: (v) => setState(() => variety = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Only my district'),
            value: districtOnly,
            onChanged: (v) => setState(() => districtOnly = v),
          ),
          const SizedBox(height: 10),
          if (commodity == null || variety == null)
            const EmptyPanel(
              icon: Icons.compare_arrows,
              title: 'Choose a commodity and variety',
              body: 'Select both to compare equivalent reports.',
            )
          else if (results.isEmpty)
            const EmptyPanel(
              icon: Icons.storefront_outlined,
              title: 'No matching reports',
              body: 'Try all Karnataka, or another variety.',
            )
          else ...[
            const Notice(
              'Sorted by quoted price. Report dates may differ; transport and selling costs are not included.',
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: results
                    .map(
                      (p) => PriceTile(
                        p,
                        showMarket: true,
                        onTap: () =>
                            openPage(context, PriceScreen(state: s, price: p)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PriceScreen extends StatefulWidget {
  const PriceScreen({super.key, required this.state, required this.price});
  final AppState state;
  final Price price;
  @override
  State<PriceScreen> createState() => _PriceScreenState();
}

class _PriceScreenState extends State<PriceScreen> {
  late Future<List<Price>> history;
  late Future<List<Json>> forecasts;
  @override
  void initState() {
    super.initState();
    history = widget.price.isDemo
        ? Future.value(DemoPriceProvider.history(widget.price))
        : widget.state.repo.history(widget.price);
    forecasts = widget.price.isDemo
        ? Future.value(const <Json>[])
        : widget.state.repo.forecasts(widget.price);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.price;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const ScenicAppBarBackground(),
        title: Text(p.name),
      ),
      body: PageBody(
        children: [
          Text(
            '${p.marketName} · ${p.variety} · ${p.grade}',
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.isDemo ? 'SAMPLE MODAL PRICE' : 'REPORTED MODAL PRICE',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.4,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    money(p.modal),
                    style: const TextStyle(
                      fontSize: 43,
                      fontWeight: FontWeight.w600,
                      color: ink,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const Text(
                    'per quintal (100 kg)',
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Minimum\n${p.min == null ? 'Not reported' : money(p.min!)}',
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Maximum\n${p.max == null ? 'Not reported' : money(p.max!)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Reported ${dayLabel(p.date)}',
                    style: const TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ),
            ),
          ),
          if (p.old) ...[
            const SizedBox(height: 12),
            const Notice(
              'This report is more than three days old. It is not a live quote.',
            ),
          ],
          SectionLabel(
            p.isDemo ? 'Market report & selling guide' : 'Early price outlook',
          ),
          FutureBuilder<List<Price>>(
            future: history,
            builder: (context, snapshot) => EarlyPriceOutlook(
              state: widget.state,
              price: p,
              history: snapshot.data ?? const [],
            ),
          ),
          const SectionLabel('Price history'),
          FutureBuilder<List<Price>>(
            future: history,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const Notice(
                  'History could not be loaded. Try again when connected.',
                );
              }
              final rows = snapshot.data ?? [];
              if (rows.length < 2) {
                return const EmptyPanel(
                  icon: Icons.show_chart,
                  title: 'History is building',
                  body:
                      'At least two dated observations are needed for a trend. Your current price remains available.',
                );
              }
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${rows.length} observations · ₹ / quintal',
                        style: const TextStyle(fontSize: 12, color: muted),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 130,
                        width: double.infinity,
                        child: CustomPaint(painter: HistoryPainter(rows)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dayLabel(rows.first.date),
                            style: const TextStyle(fontSize: 10, color: muted),
                          ),
                          Text(
                            dayLabel(rows.last.date),
                            style: const TextStyle(fontSize: 10, color: muted),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      ...rows.reversed
                          .take(6)
                          .map(
                            (r) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(dayLabel(r.date)),
                                  Text(money(r.modal)),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              );
            },
          ),
          SectionLabel(
            p.isDemo
                ? 'Live forecast unavailable for sample data'
                : 'Forecast by date',
          ),
          FutureBuilder<List<Json>>(
            future: forecasts,
            builder: (context, snapshot) {
              final rows = snapshot.data ?? [];
              if (rows.isEmpty) {
                return EmptyPanel(
                  icon: Icons.event_note_outlined,
                  title: p.isDemo
                      ? 'Sample report only'
                      : 'Forecast not available yet',
                  body: p.isDemo
                      ? 'The sample selling guide above uses simulated prices. A live AI outlook will be available after verified market reports are added.'
                      : 'Price estimates will appear here when forecasts are available for this market.',
                );
              }
              return Card(
                child: Column(
                  children: rows
                      .map(
                        (f) => ListTile(
                          title: Text(
                            dayLabel(DateTime.parse(f['target_date'])),
                          ),
                          subtitle: Text(
                            'Estimated ${money(number(f['low'])!)} – ${money(number(f['high'])!)}',
                          ),
                          trailing: Text(money(number(f['expected'])!)),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () => openPage(
              context,
              CompareScreen(state: widget.state, initial: p),
            ),
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Compare this variety'),
          ),
          const SizedBox(height: 20),
          Text(
            p.isDemo
                ? 'Sample dataset · Simulated prices and dates for preview only; not live market information.'
                : 'Source: data.gov.in · Actual sale prices can differ from reported modal prices.',
            style: const TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ),
    );
  }
}

class EarlyPriceOutlook extends StatefulWidget {
  const EarlyPriceOutlook({
    super.key,
    required this.state,
    required this.price,
    required this.history,
  });

  final AppState state;
  final Price price;
  final List<Price> history;

  @override
  State<EarlyPriceOutlook> createState() => _EarlyPriceOutlookState();
}

class _EarlyPriceOutlookState extends State<EarlyPriceOutlook> {
  Future<Json>? prediction;

  @override
  void initState() {
    super.initState();
    _loadPrediction();
  }

  void _loadPrediction({bool force = false}) {
    if (widget.price.isDemo) return;
    prediction = widget.state.repo.priceOutlook(
      widget.price,
      language: widget.state.language,
      force: force,
    );
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.price;
    final outlook = PriceOutlook.fromReports(price, widget.history);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights_outlined, color: accentBlue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reported range · ₹ / quintal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OutlookValue(label: 'Low seen', value: outlook.low),
                ),
                Expanded(
                  child: _OutlookValue(
                    label: 'Current modal',
                    value: price.modal,
                    emphasized: true,
                  ),
                ),
                Expanded(
                  child: _OutlookValue(label: 'High seen', value: outlook.high),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Reported prices · ${outlook.reportCount} dated observations',
              style: const TextStyle(fontSize: 11, color: muted),
            ),
            const Divider(height: 24),
            if (price.isDemo)
              _DemoSellingGuide(price: price, history: widget.history)
            else
              FutureBuilder<Json>(
                future: prediction!,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('Generating LLM price outlook…'),
                          ),
                        ],
                      ),
                    );
                  }
                  final data = snapshot.data;
                  if (snapshot.hasError || data == null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.state.signedIn
                              ? 'LLM outlook unavailable. It needs an internet connection and at least three dated reports.'
                              : 'Sign in to request an LLM price outlook. At least three dated reports are needed.',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: muted,
                          ),
                        ),
                        if (widget.state.signedIn)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () =>
                                  setState(() => _loadPrediction(force: true)),
                              icon: const Icon(Icons.refresh, size: 17),
                              label: const Text('Try again'),
                            ),
                          ),
                      ],
                    );
                  }
                  final low = number(data['low']);
                  final expected = number(data['expected']);
                  final high = number(data['high']);
                  final advice = data['sell_advice']?.toString() ?? '';
                  if (low == null ||
                      expected == null ||
                      high == null ||
                      advice.isEmpty) {
                    return const Text(
                      'The LLM response was incomplete. Use the reported prices and check again later.',
                      style: TextStyle(fontSize: 13, color: muted),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LLM estimate · next 7 days · ₹ / quintal',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _OutlookValue(label: 'Low', value: low),
                          ),
                          Expanded(
                            child: _OutlookValue(
                              label: 'Expected',
                              value: expected,
                              emphasized: true,
                            ),
                          ),
                          Expanded(
                            child: _OutlookValue(label: 'High', value: high),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.tips_and_updates_outlined,
                            size: 20,
                            color: accentBlue,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              advice,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Confidence: ${data['confidence'] ?? 'low'} · Based on ${data['report_count'] ?? 'recent'} reports.',
                        style: const TextStyle(fontSize: 11, color: muted),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 12),
            if (!price.isDemo)
              const Text(
                'AI estimates can be wrong and are not a guarantee. Check the latest mandi quote and account for your costs before selling.',
                style: TextStyle(fontSize: 11, color: muted, height: 1.4),
              ),
          ],
        ),
      ),
    );
  }
}

class _DemoSellingGuide extends StatelessWidget {
  const _DemoSellingGuide({required this.price, required this.history});
  final Price price;
  final List<Price> history;

  @override
  Widget build(BuildContext context) {
    final average = history.isEmpty
        ? price.modal
        : history.map((p) => p.modal).reduce((a, b) => a + b) / history.length;
    final advice = price.modal >= average * 1.015
        ? 'Sample suggestion: the current price is above its recent sample average. If your crop is ready, compare nearby mandi quotes and consider selling in batches.'
        : price.modal <= average * .985
        ? 'Sample suggestion: the current price is below its recent sample average. If storage and crop quality allow, check the next dated report before deciding.'
        : 'Sample suggestion: the current price is close to its recent sample average. Consider staggered selling and compare nearby mandi quotes.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: accentBlue, size: 19),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Sample selling guide',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(advice, style: const TextStyle(fontSize: 13, height: 1.45)),
        const SizedBox(height: 8),
        Text(
          'Sample report dated ${dayLabel(price.date)} · Guidance uses simulated prices, not a live forecast.',
          style: const TextStyle(fontSize: 11, color: muted, height: 1.4),
        ),
      ],
    );
  }
}

class _OutlookValue extends StatelessWidget {
  const _OutlookValue({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: muted),
      ),
      const SizedBox(height: 5),
      Text(
        money(value),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: emphasized ? 16 : 14,
          fontWeight: FontWeight.w600,
          color: emphasized ? accentBlue : ink,
        ),
      ),
    ],
  );
}

class HistoryPainter extends CustomPainter {
  HistoryPainter(this.rows);
  final List<Price> rows;
  @override
  void paint(Canvas canvas, Size size) {
    final low = rows.map((p) => p.modal).reduce(math.min),
        high = rows.map((p) => p.modal).reduce(math.max);
    final span = math.max(1.0, high - low);
    final elapsed = math.max(
      1,
      rows.last.date.difference(rows.first.date).inDays,
    );
    final grid = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final y = i * size.height / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path();
    for (int i = 0; i < rows.length; i++) {
      final x =
          rows[i].date.difference(rows.first.date).inDays /
          elapsed *
          size.width;
      final y =
          size.height - 8 - (rows[i].modal - low) / span * (size.height - 16);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = accentBlue);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = accentBlue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant HistoryPainter oldDelegate) =>
      oldDelegate.rows != rows;
}
