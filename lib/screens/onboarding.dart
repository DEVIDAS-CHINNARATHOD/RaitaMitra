import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../state.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'email_auth.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.state});
  final AppState state;
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool signing = false;
  int illustrationPage = 0;
  final PageController illustrationController = PageController();

  @override
  void dispose() {
    illustrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: height * .57,
                  child: PageView(
                    controller: illustrationController,
                    onPageChanged: (page) =>
                        setState(() => illustrationPage = page),
                    children: const [
                      _OnboardingFarmerImage(
                        asset: 'assets/images/raita_mitra_sowing_farmer.svg',
                        description: 'Farmer sowing seeds',
                      ),
                      _OnboardingFarmerImage(
                        asset: 'assets/images/raita_mitra_watering_farmer.svg',
                        description: 'Farmer watering seedlings',
                      ),
                      _OnboardingMarketImage(),
                    ],
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 24,
                  right: 18,
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/raitha_mitra_logo.png',
                        width: 34,
                        height: 34,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 9),
                      const Text(
                        'RAITHA MITRA',
                        style: TextStyle(
                          letterSpacing: 1.8,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            s.setLanguage(s.language == 'en' ? 'kn' : 'en'),
                        child: Text(s.language == 'en' ? 'ಕನ್ನಡ' : 'English'),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: height * .48,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(26, 24, 26, 18),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            final selected = illustrationPage == index;
                            return GestureDetector(
                              onTap: () => illustrationController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                              ),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: selected ? 22 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? accentBlue
                                        : const Color(0xffC9DDE5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.t(
                            'Know your market.\nGrow with confidence.',
                            'ಮಾರುಕಟ್ಟೆ ತಿಳಿಯಿರಿ.\nಆತ್ಮವಿಶ್ವಾಸದಿಂದ ಬೆಳೆಯಿರಿ.',
                          ),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: ink,
                                fontWeight: FontWeight.w700,
                                height: 1.12,
                              ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          s.t(
                            'Daily mandi prices and crop insights for farmers across Karnataka.',
                            'ಕರ್ನಾಟಕದ ರೈತರಿಗಾಗಿ ದೈನಂದಿನ ಮಂಡಿ ಬೆಲೆ ಮತ್ತು ಬೆಳೆ ಮಾಹಿತಿ.',
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: muted,
                            height: 1.4,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: signing
                                ? null
                                : () async {
                                    setState(() => signing = true);
                                    try {
                                      await s.signIn();
                                    } catch (error) {
                                      if (context.mounted) {
                                        toast(
                                          context,
                                          'Could not start Google sign-in: $error',
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() => signing = false);
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.login, size: 20),
                            label: Text(
                              s.t(
                                'Continue with Google',
                                'Google ಮೂಲಕ ಮುಂದುವರಿಸಿ',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                openPage(context, EmailAuthScreen(state: s)),
                            icon: const Icon(Icons.email_outlined),
                            label: Text(
                              s.t(
                                'Sign in or register with email',
                                'ಇಮೇಲ್ ಮೂಲಕ ಸೈನ್ ಇನ್ ಅಥವಾ ನೋಂದಣಿ',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingFarmerImage extends StatelessWidget {
  const _OnboardingFarmerImage({
    required this.asset,
    required this.description,
  });

  final String asset;
  final String description;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: description,
    child: ClipRect(
      child: SvgPicture.asset(
        asset,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
      ),
    ),
  );
}

class _OnboardingMarketImage extends StatelessWidget {
  const _OnboardingMarketImage();

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Farmer checking market prices and crop reports',
    child: ClipRect(
      child: Image.asset(
        'assets/images/raitha_mitra_login_market.png',
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
      ),
    ),
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.state, this.editing = false});
  final AppState state;
  final bool editing;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController name;
  String? district, market;
  Uint8List? selectedPhoto;
  String photoContentType = 'image/jpeg';
  bool saving = false, locating = false;
  @override
  void initState() {
    super.initState();
    final s = widget.state;
    name = TextEditingController(text: s.name);
    district = s.districtId.isEmpty ? null : s.districtId;
    market = s.marketId.isEmpty ? null : s.marketId;
    if (!widget.editing && s.marketId.isEmpty) {
      Future.microtask(() => s.detectLocation(autoSelectNearest: true));
    }
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> choosePhoto() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 86,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        selectedPhoto = bytes;
        photoContentType = image.mimeType ?? 'image/jpeg';
      });
    } catch (_) {
      if (mounted) toast(context, 'Could not open the photo picker.');
    }
  }

  Future<void> locate() async {
    setState(() => locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Location is turned off');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Location permission is unavailable');
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final candidates = widget.state.markets
          .where((m) => m.verified && m.latitude != null && m.longitude != null)
          .toList();
      if (candidates.isEmpty) {
        widget.state.setCurrentLocation(
          '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}',
        );
        if (mounted) {
          toast(
            context,
            'Location found. Verified mandi coordinates are needed to choose the nearest market; please select one below.',
          );
        }
        return;
      }
      candidates.sort(
        (a, b) =>
            Geolocator.distanceBetween(
              p.latitude,
              p.longitude,
              a.latitude!,
              a.longitude!,
            ).compareTo(
              Geolocator.distanceBetween(
                p.latitude,
                p.longitude,
                b.latitude!,
                b.longitude!,
              ),
            ),
      );
      if (mounted) {
        setState(() {
          district = candidates.first.districtId;
          market = candidates.first.id;
        });
      }
    } catch (_) {
      if (mounted) {
        toast(
          context,
          'Location could not be read. You can select a mandi manually.',
        );
      }
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final markets = s.markets.where((m) => m.districtId == district).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.t(
            widget.editing ? 'Edit profile' : 'Make it local',
            widget.editing ? 'ಪ್ರೊಫೈಲ್ ಸಂಪಾದಿಸಿ' : 'ನಿಮ್ಮ ಆಯ್ಕೆ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => s.setLanguage(s.language == 'en' ? 'kn' : 'en'),
            child: Text(s.language == 'en' ? 'ಕನ್ನಡ' : 'English'),
          ),
        ],
      ),
      body: PageBody(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: paleBlue,
                      backgroundImage: selectedPhoto != null
                          ? MemoryImage(selectedPhoto!)
                          : profilePhotoProvider(s.avatarUrl),
                      child: selectedPhoto == null && s.avatarUrl.isEmpty
                          ? const Icon(
                              Icons.person_outline,
                              size: 48,
                              color: accentBlue,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: accentBlue,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          tooltip: s.t(
                            'Choose profile photo',
                            'ಚಿತ್ರ ಆಯ್ಕೆಮಾಡಿ',
                          ),
                          onPressed: choosePhoto,
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          color: Colors.white,
                          constraints: const BoxConstraints.tightFor(
                            width: 36,
                            height: 36,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: choosePhoto,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text(s.t('Change photo', 'ಚಿತ್ರ ಬದಲಿಸಿ')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            s.t(
              widget.editing ? 'Your profile details' : 'Choose your mandi',
              widget.editing
                  ? 'ನಿಮ್ಮ ಪ್ರೊಫೈಲ್ ವಿವರಗಳು'
                  : 'ನಿಮ್ಮ ಮಾರುಕಟ್ಟೆಯಿಂದ\nಪ್ರಾರಂಭಿಸಿ.',
            ),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 14),
          Text(
            s.t(
              widget.editing
                  ? 'Update your name, profile photo and preferred mandi.'
                  : 'Choose where you usually sell. You can change this any time.',
              widget.editing
                  ? 'ನಿಮ್ಮ ಹೆಸರು, ಚಿತ್ರ ಮತ್ತು ಆದ್ಯತೆಯ ಮಾರುಕಟ್ಟೆಯನ್ನು ಬದಲಿಸಿ.'
                  : 'ನೀವು ಸಾಮಾನ್ಯವಾಗಿ ಮಾರಾಟ ಮಾಡುವ ಮಾರುಕಟ್ಟೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ.',
            ),
            style: const TextStyle(color: muted, fontSize: 16),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: s.t('Your name (optional)', 'ನಿಮ್ಮ ಹೆಸರು'),
            ),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: district,
            isExpanded: true,
            decoration: InputDecoration(labelText: s.t('District', 'ಜಿಲ್ಲೆ')),
            items: s.districts
                .map(
                  (d) => DropdownMenuItem<String>(
                    value: d['id'],
                    child: Text(d['name']),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() {
              district = v;
              market = null;
            }),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            key: ValueKey(district),
            initialValue: market,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: s.t('Preferred mandi', 'ಆದ್ಯತೆಯ ಮಾರುಕಟ್ಟೆ'),
            ),
            items: markets
                .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                .toList(),
            onChanged: (v) => setState(() => market = v),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: locating ? null : locate,
            icon: const Icon(Icons.my_location, size: 19),
            label: Text(s.t('Find nearest mandi', 'ಹತ್ತಿರದ ಮಾರುಕಟ್ಟೆ ಹುಡುಕಿ')),
          ),
          const SizedBox(height: 20),
          const Notice(
            'Directory names are available for all listed districts. Distances will appear once market coordinates are verified.',
          ),
          const SizedBox(height: 30),
          FilledButton(
            onPressed: saving || district == null || market == null
                ? null
                : () async {
                    setState(() => saving = true);
                    try {
                      final photoUrl = selectedPhoto == null
                          ? null
                          : await s.uploadProfilePhoto(
                              selectedPhoto!,
                              photoContentType,
                            );
                      await s.saveProfile(
                        newName: name.text.trim(),
                        district: district!,
                        market: market!,
                        newAvatarUrl: photoUrl,
                      );
                      if (context.mounted && widget.editing) {
                        Navigator.pop(context);
                      }
                    } catch (_) {
                      if (context.mounted) {
                        toast(
                          context,
                          'Could not save your preferences. Please try again.',
                        );
                      }
                    } finally {
                      if (mounted) setState(() => saving = false);
                    }
                  },
            child: Text(
              saving
                  ? s.t('Saving…', 'ಉಳಿಸಲಾಗುತ್ತಿದೆ…')
                  : s.t(
                      widget.editing ? 'Save preferences' : 'See market prices',
                      'ಬೆಲೆಗಳನ್ನು ನೋಡಿ',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
