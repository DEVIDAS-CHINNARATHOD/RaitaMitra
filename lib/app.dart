import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: 0,
                    left: 12,
                    right: 12,
                    height: MediaQuery.sizeOf(context).height * .63,
                    child: SvgPicture.asset(
                      'assets/images/raita_mitra_sowing_farmer.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 76,
                    height: 154,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(26),
                        ),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Raitha Mitra',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Growing with Karnataka',
                            style: TextStyle(color: muted, fontSize: 14),
                          ),
                          SizedBox(height: 14),
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 10,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
