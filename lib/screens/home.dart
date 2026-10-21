import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'onboarding.dart';
import 'markets.dart';
import 'crops.dart';
import 'support.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.state,
    required this.onMarkets,
    required this.onCrops,
    required this.onProfile,
  });
  final AppState state;
  final VoidCallback onMarkets, onCrops, onProfile;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String search = '';
  bool showAllPrices = false;
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final prices = s.homePrices
        .where((p) => p.name.toLowerCase().contains(search.toLowerCase()))
        .toList();
    final visiblePrices = showAllPrices ? prices : prices.take(3).toList();
    final location = s.districtId.isEmpty
        ? s.t('Choose your mandi', 'ಮಾರುಕಟ್ಟೆ ಆಯ್ಕೆಮಾಡಿ')
        : '${s.districtName(s.districtId)}, Karnataka';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: headerBlue,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Row(
          children: [
            Icon(Icons.agriculture, size: 23, color: Colors.white),
            SizedBox(width: 9),
            Text(
              'Raitha Mitra',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Alerts',
            onPressed: () => openPage(context, AlertsScreen(state: s)),
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
          IconButton(
            tooltip: s.t('Profile', 'ಪ್ರೊಫೈಲ್'),
            onPressed: widget.onProfile,
            icon: ProfileAvatar(photo: s.avatarUrl, radius: 18),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => s.refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(-20, 0, -20, 0),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              decoration: const BoxDecoration(
                color: headerBlue,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.t('YOUR LOCATION', 'ನಿಮ್ಮ ಸ್ಥಳ'),
                              style: const TextStyle(
                                color: Colors.white70,
                                letterSpacing: 1.1,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              location,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => openPage(
                          context,
                          ProfileScreen(state: s, editing: true),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(s.t('Change', 'ಬದಲಿಸಿ')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    s.t('Market at a glance', 'ಮಾರುಕಟ್ಟೆ ಮಾಹಿತಿ'),
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: paleBlue,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.t('SELECTED MANDI', 'ಆಯ್ಕೆ ಮಾಡಿದ ಮಾರುಕಟ್ಟೆ'),
                          style: const TextStyle(
                            color: accentBlue,
                            letterSpacing: 1,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          s.selectedMarket?.name ??
                              s.t('Select a mandi', 'ಮಾರುಕಟ್ಟೆ ಆಯ್ಕೆಮಾಡಿ'),
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: line),
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${s.homePrices.length} ${s.t('available price reports', 'ಬೆಲೆ ವರದಿಗಳು')}',
                                style: const TextStyle(
                                  color: ink,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (s.busy)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: accentBlue,
                                ),
                              )
                            else
                              InkWell(
                                onTap: () => s.refresh(),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.refresh,
                                    size: 20,
                                    color: ink,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SectionLabel(
              s.t('Commodity prices', 'ಬೆಳೆ ಬೆಲೆಗಳು'),
              action: s.t('Compare', 'ಹೋಲಿಸಿ'),
              onTap: () => openPage(context, CompareScreen(state: s)),
            ),
            TextField(
              onChanged: (v) => setState(() {
                search = v;
                showAllPrices = false;
              }),
              decoration: InputDecoration(
                hintText: s.t('Search a commodity', 'ಬೆಳೆ ಹುಡುಕಿ'),
                prefixIcon: const Icon(Icons.search, size: 21),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            if (prices.isEmpty)
              EmptyPanel(
                icon: Icons.receipt_long_outlined,
                title: search.isEmpty
                    ? s.t(
                        'No reports loaded for this mandi',
                        'ಈ ಮಾರುಕಟ್ಟೆಯ ವರದಿ ಲಭ್ಯವಿಲ್ಲ',
                      )
                    : s.t('No matching commodity', 'ಬೆಳೆ ಕಂಡುಬಂದಿಲ್ಲ'),
                body: s.t(
                  'Check the source for available reports, or explore another market.',
                  'ಲಭ್ಯವಿರುವ ವರದಿಗಳನ್ನು ಪರಿಶೀಲಿಸಿ ಅಥವಾ ಬೇರೆ ಮಾರುಕಟ್ಟೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ.',
                ),
                action: s.busy ? 'Checking source…' : 'Check available prices',
                onAction: s.busy ? null : () => s.refresh(),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (int i = 0; i < visiblePrices.length; i++) ...[
                      PriceTile(
                        visiblePrices[i],
                        onTap: () => openPage(
                          context,
                          PriceScreen(state: s, price: visiblePrices[i]),
                        ),
                      ),
                      if (i < visiblePrices.length - 1)
                        const Divider(indent: 16, endIndent: 16),
                    ],
                  ],
                ),
              ),
            if (prices.length > 3) ...[
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => showAllPrices = !showAllPrices),
                  icon: Icon(
                    showAllPrices ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: Text(
                    showAllPrices
                        ? s.t('Show less', 'ಕಡಿಮೆ ತೋರಿಸಿ')
                        : s.t(
                            'Show more (${prices.length - 3})',
                            'ಇನ್ನಷ್ಟು ತೋರಿಸಿ (${prices.length - 3})',
                          ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              s.t(
                'Source: data.gov.in · Coverage may be partial. Each price shows its report date.',
                'ಮೂಲ: data.gov.in · ಪ್ರತಿ ಬೆಲೆಯ ವರದಿ ದಿನಾಂಕ ನೋಡಿ.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SectionLabel(
              s.t('My crops', 'ನನ್ನ ಬೆಳೆಗಳು'),
              action: s.t('View all', 'ಎಲ್ಲಾ ನೋಡಿ'),
              onTap: widget.onCrops,
            ),
            if (s.crops.isEmpty)
              EmptyPanel(
                icon: Icons.grass_outlined,
                title: s.t(
                  'A place for your next harvest',
                  'ನಿಮ್ಮ ಮುಂದಿನ ಕೊಯ್ಲಿನ ಮಾಹಿತಿ',
                ),
                body: s.t(
                  'Add what you grow to keep its market price and harvest date together.',
                  'ನಿಮ್ಮ ಬೆಳೆ ಮತ್ತು ಕೊಯ್ಲಿನ ದಿನಾಂಕವನ್ನು ಸೇರಿಸಿ.',
                ),
                action: s.t('Add your first crop', 'ನಿಮ್ಮ ಬೆಳೆ ಸೇರಿಸಿ'),
                onAction: () => openPage(context, CropFormScreen(state: s)),
              )
            else
              ...s.crops
                  .take(2)
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CropCard(state: s, crop: c),
                    ),
                  ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: widget.onMarkets,
              icon: const Icon(Icons.map_outlined, size: 19),
              label: Text(
                s.t(
                  'Explore ${s.markets.length} listed mandis',
                  'ಪಟ್ಟಿಮಾಡಿದ ಮಾರುಕಟ್ಟೆಗಳನ್ನು ನೋಡಿ',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
