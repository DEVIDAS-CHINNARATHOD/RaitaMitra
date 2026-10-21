import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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
  int? temperatureC, weatherCode;
  bool weatherLoading = true;
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadWeather);
  }

  Future<void> _loadWeather() async {
    final s = widget.state;
    if (s.currentLatitude == null || s.currentLongitude == null) {
      await s.detectLocation();
    }
    final latitude = s.currentLatitude;
    final longitude = s.currentLongitude;
    if (latitude == null || longitude == null) {
      if (mounted) setState(() => weatherLoading = false);
      return;
    }
    if (mounted) setState(() => weatherLoading = true);
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'current': 'temperature_2m,weather_code',
        'timezone': 'auto',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) throw const FormatException();
      final current =
          (jsonDecode(response.body) as Map<String, dynamic>)['current']
              as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        temperatureC = (current['temperature_2m'] as num).round();
        weatherCode = (current['weather_code'] as num).round();
        weatherLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => weatherLoading = false);
    }
  }

  IconData get _weatherIcon {
    final code = weatherCode;
    if (code == null) return Icons.cloud_outlined;
    if (code == 0) return Icons.wb_sunny_outlined;
    if (code <= 3) return Icons.cloud_queue;
    if (code == 45 || code == 48) return Icons.blur_on;
    return Icons.grain;
  }

  @override
  Widget build(BuildContext context) {
    const toolbarHeight = 78.0;
    final s = widget.state;
    final prices = s.homePrices
        .where((p) => p.name.toLowerCase().contains(search.toLowerCase()))
        .toList();
    final visiblePrices = showAllPrices ? prices : prices.take(3).toList();
    final location = s.currentLocation.isEmpty
        ? s.t('Finding your location…', 'ನಿಮ್ಮ ಸ್ಥಳವನ್ನು ಹುಡುಕಲಾಗುತ್ತಿದೆ…')
        : s.currentLocation;
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: headerBlue,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: toolbarHeight,
        elevation: 0,
        shadowColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        ),
        clipBehavior: Clip.antiAlias,
        title: Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.t('YOUR LOCATION', 'ನಿಮ್ಮ ಸ್ಥಳ'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Tooltip(
            message: 'Current weather · Open-Meteo',
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (weatherLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: Colors.white,
                      ),
                    )
                  else ...[
                    Icon(_weatherIcon, color: Colors.white, size: 18),
                    const SizedBox(width: 3),
                    Text(
                      temperatureC == null ? '--°' : '$temperatureC°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.paddingOf(context).top + toolbarHeight,
            child: const ColoredBox(color: Colors.white),
          ),
          RefreshIndicator(
            onRefresh: () => s.refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + toolbarHeight,
                20,
                100,
              ),
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: headerBlue,
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.t('Market at a glance', 'ಮಾರುಕಟ್ಟೆ ಮಾಹಿತಿ'),
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: paleBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 30,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.t(
                                          'SELECTED MANDI',
                                          'ಆಯ್ಕೆ ಮಾಡಿದ ಮಾರುಕಟ್ಟೆ',
                                        ),
                                        style: const TextStyle(
                                          color: accentBlue,
                                          letterSpacing: 1,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        s.selectedMarket?.name ??
                                            s.t(
                                              'Select a mandi',
                                              'ಮಾರುಕಟ್ಟೆ ಆಯ್ಕೆಮಾಡಿ',
                                            ),
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: ink,
                                        ),
                                      ),
                                      if (s.selectedMarket != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '${s.districtName(s.selectedMarket!.districtId)}, Karnataka',
                                          style: const TextStyle(
                                            color: muted,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => openPage(
                                    context,
                                    ProfileScreen(state: s, editing: true),
                                  ),
                                  icon: const Icon(
                                    Icons.edit_location_alt_outlined,
                                    size: 16,
                                  ),
                                  label: Text(
                                    s.t('Change mandi', 'ಮಾರುಕಟ್ಟೆ ಬದಲಿಸಿ'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: line),
                            const SizedBox(height: 9),
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
                    action: s.busy
                        ? 'Checking source…'
                        : 'Check available prices',
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
        ],
      ),
    );
  }
}
