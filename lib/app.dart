import 'package:flutter/material.dart';
import 'state.dart';
import 'ui/theme.dart';
import 'screens/onboarding.dart';
import 'screens/home.dart';
import 'screens/markets.dart';
import 'screens/crops.dart';
import 'screens/support.dart';

class RaithaMitraApp extends StatefulWidget {
  const RaithaMitraApp({super.key, required this.state});
  final AppState state;
  @override
  State<RaithaMitraApp> createState() => _RaithaMitraAppState();
}

class _RaithaMitraAppState extends State<RaithaMitraApp> {
  final navigator = GlobalKey<NavigatorState>();
  AppState get state => widget.state;
  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigator,
    builder: (context, child) =>
        ListenableBuilder(listenable: state, builder: (context, _) => child!),
    title: 'Raitha Mitra',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    home: ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        if (!state.ready) {
          return Scaffold(
            body: SafeArea(
              child: Stack(
                children: [
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.agriculture, size: 44, color: accentBlue),
                        SizedBox(height: 16),
                        Text(
                          'Raitha Mitra',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 28),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 22,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => navigator.currentState!.push(
                        MaterialPageRoute(
                          builder: (_) => HelpScreen(state: state),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(state.t('Ask Mitra', 'ಮಿತ್ರನನ್ನು ಕೇಳಿ')),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (!state.entered) return WelcomeScreen(state: state);
        if (!state.onboarded) return ProfileScreen(state: state);
        return MainShell(state: state);
      },
    ),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.state});
  final AppState state;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [
          HomeScreen(
            state: s,
            onMarkets: () => setState(() => index = 1),
            onCrops: () => setState(() => index = 2),
            onProfile: () => setState(() => index = 4),
          ),
          MarketsScreen(state: s),
          CropsScreen(state: s),
          SupportScreen(state: s),
          ProfileTabScreen(state: s),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: paleBlue,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: line),
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => setState(() => index = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: s.t('Home', 'ಮುಖಪುಟ'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.storefront_outlined),
                selectedIcon: const Icon(Icons.storefront),
                label: s.t('Markets', 'ಮಾರುಕಟ್ಟೆ'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.grass_outlined),
                selectedIcon: const Icon(Icons.grass),
                label: s.t('My Crops', 'ನನ್ನ ಬೆಳೆ'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.help_outline),
                selectedIcon: const Icon(Icons.help),
                label: s.t('Support', 'ಸಹಾಯ'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: s.t('Profile', 'ಪ್ರೊಫೈಲ್'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
