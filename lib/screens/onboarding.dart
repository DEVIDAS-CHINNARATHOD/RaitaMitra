import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../state.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.state});
  final AppState state;
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  bool signing = false;
  late final AnimationController illustrationMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    illustrationMotion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
          children: [
            Row(
              children: [
                const Icon(Icons.agriculture, color: accentBlue, size: 25),
                const SizedBox(width: 9),
                const Text(
                  'RAITHA MITRA',
                  style: TextStyle(
                    letterSpacing: 1.8,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: illustrationMotion,
              builder: (context, _) => Transform.translate(
                offset: Offset(0, -4 + illustrationMotion.value * 8),
                child: const _FarmWelcomeIllustration(),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              s.t(
                'Your farm.\nBetter informed.',
                'ನಿಮ್ಮ ಬೆಳೆ.\nನಿಮ್ಮ ಮಾರುಕಟ್ಟೆ.\nಸ್ಪಷ್ಟ ಮಾಹಿತಿ.',
              ),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            Text(
              s.t(
                'Mandi prices across Karnataka, with a place for every crop you grow.',
                'ಕರ್ನಾಟಕದ ಮಾರುಕಟ್ಟೆ ಬೆಲೆಗಳು ಮತ್ತು ನಿಮ್ಮ ಬೆಳೆಗಳ ಮಾಹಿತಿ ಒಂದೇ ಸ್ಥಳದಲ್ಲಿ.',
              ),
              style: const TextStyle(fontSize: 16, color: muted, height: 1.5),
            ),
            const SizedBox(height: 34),
            FilledButton.icon(
              onPressed: signing
                  ? null
                  : () async {
                      setState(() => signing = true);
                      try {
                        await s.signIn();
                      } catch (_) {
                        if (context.mounted) {
                          toast(
                            context,
                            'Google sign-in is not available right now. Please try again later or explore on this device.',
                          );
                        }
                      } finally {
                        if (mounted) setState(() => signing = false);
                      }
                    },
              icon: const Icon(Icons.login, size: 20),
              label: Text(
                s.t('Continue with Google', 'Google ಮೂಲಕ ಮುಂದುವರಿಸಿ'),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => s.enterPreview(),
              child: Text(
                s.t('Explore on this device', 'ಈ ಸಾಧನದಲ್ಲಿ ಅನ್ವೇಷಿಸಿ'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.t(
                'Exploring keeps your crops on this phone. Sign in to save them to your account.',
                'ಖಾತೆ ಇಲ್ಲದೆ ಉಳಿಸಿದ ಬೆಳೆಗಳು ಈ ಫೋನ್‌ನಲ್ಲಿ ಮಾತ್ರ ಇರುತ್ತವೆ.',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 28),
            const Center(
              child: Text(
                'KARNATAKA  /  ರೈತ ಮಿತ್ರ',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.7,
                  color: muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmWelcomeIllustration extends StatelessWidget {
  const _FarmWelcomeIllustration();

  @override
  Widget build(BuildContext context) => Container(
    height: 174,
    decoration: BoxDecoration(
      color: paleBlue,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Center(
      child: Container(
        width: 112,
        height: 112,
        decoration: const BoxDecoration(color: skyBlue, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const Icon(Icons.agriculture, size: 62, color: accentBlue),
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
    final candidates = widget.state.markets
        .where((m) => m.verified && m.latitude != null && m.longitude != null)
        .toList();
    if (candidates.isEmpty) {
      toast(
        context,
        'Verified market coordinates are not available yet. Please select your district and mandi.',
      );
      return;
    }
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
