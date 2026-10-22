import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/models.dart';
import 'data/repository.dart';
import 'data/demo_price_provider.dart';

class AppState extends ChangeNotifier {
  AppState(this.repo);
  final Repository repo;
  late SharedPreferences prefs;
  bool ready = false,
      busy = false,
      entered = false,
      onboarded = false,
      passwordRecovery = false,
      offline = false;
  String language = 'en',
      name = '',
      avatarUrl = '',
      districtId = '',
      marketId = '',
      message = '';
  String currentLocation = '';
  double? currentLatitude, currentLongitude;
  bool locating = false;
  List<Json> districts = [], alerts = [];
  List<Market> markets = [];
  List<Price> prices = [];
  List<FarmCrop> crops = [];
  DateTime? checkedAt;
  StreamSubscription<AuthState>? _auth;
  bool get signedIn => repo.client?.auth.currentUser != null;
  String t(String english, String kannada) =>
      language == 'kn' ? kannada : english;
  Market? get selectedMarket =>
      markets.where((m) => m.id == marketId).firstOrNull;
  String districtName(String id) =>
      districts.where((d) => d['id'] == id).firstOrNull?['name'] ?? id;
  void setCurrentLocation(String value) {
    currentLocation = value;
    notifyListeners();
  }

  Future<void> detectLocation({bool autoSelectNearest = false}) async {
    if (locating) return;
    locating = true;
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        currentLocation = 'Location services are off';
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        currentLocation = 'Location permission needed';
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      currentLatitude = position.latitude;
      currentLongitude = position.longitude;
      currentLocation =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      try {
        final places = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (places.isNotEmpty) {
          final place = places.first;
          final locality = place.subLocality?.trim().isNotEmpty == true
              ? place.subLocality!.trim()
              : place.locality?.trim().isNotEmpty == true
              ? place.locality!.trim()
              : place.subAdministrativeArea?.trim();
          if (locality != null && locality.isNotEmpty) {
            currentLocation =
                '$locality${place.administrativeArea?.isNotEmpty == true ? ', ${place.administrativeArea}' : ''}';
          }
        }
      } catch (_) {
        // Coordinates still give a useful location when reverse geocoding is unavailable.
      }
      if (autoSelectNearest && marketId.isEmpty) {
        final candidates = markets
            .where(
              (m) => m.verified && m.latitude != null && m.longitude != null,
            )
            .toList();
        if (candidates.isNotEmpty) {
          candidates.sort(
            (a, b) =>
                Geolocator.distanceBetween(
                  position.latitude,
                  position.longitude,
                  a.latitude!,
                  a.longitude!,
                ).compareTo(
                  Geolocator.distanceBetween(
                    position.latitude,
                    position.longitude,
                    b.latitude!,
                    b.longitude!,
                  ),
                ),
          );
          final nearest = candidates.first;
          await saveProfile(
            newName: name,
            district: nearest.districtId,
            market: nearest.id,
          );
        }
      }
    } catch (_) {
      currentLocation = 'Could not determine location';
    } finally {
      locating = false;
      notifyListeners();
    }
  }

  List<Price> get homePrices =>
      prices.where((p) => p.marketId == marketId).toList();
  Future<void> initialize() async {
    try {
      prefs = await SharedPreferences.getInstance();
      language = prefs.getString('language') ?? 'en';
      await repo.open();
      final dir = await repo.directory();
      districts = (dir['districts'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      markets = (dir['markets'] as List)
          .map((e) => Market.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _readPreferences();
      entered = signedIn;
      if (signedIn) await _loadProfile();
      _auth = repo.client?.auth.onAuthStateChange.listen((event) async {
        if (event.event == AuthChangeEvent.passwordRecovery) {
          passwordRecovery = true;
          entered = true;
          notifyListeners();
          return;
        }
        if (event.event == AuthChangeEvent.signedOut) {
          passwordRecovery = false;
          entered = false;
          onboarded = false;
          name = '';
          avatarUrl = '';
          marketId = '';
          districtId = '';
          crops = [];
          alerts = [];
          notifyListeners();
          return;
        }
        if (event.event == AuthChangeEvent.signedIn) {
          entered = true;
          _readPreferences();
          await _loadProfile();
          await loadPersonal();
          notifyListeners();
        }
      });
      await Future.wait([loadPrices(), loadPersonal()]);
    } catch (_) {
      message = 'Could not finish loading. Restart the app to retry.';
    }
    ready = true;
    notifyListeners();
  }

  void _readPreferences() {
    final prefix = repo.owner;
    name = prefs.getString('$prefix:name') ?? '';
    avatarUrl = prefs.getString('$prefix:avatar_url') ?? '';
    districtId = prefs.getString('$prefix:district') ?? '';
    marketId = prefs.getString('$prefix:market') ?? '';
    onboarded = marketId.isNotEmpty;
  }

  Future<void> _loadProfile() async {
    try {
      final metadata = repo.client!.auth.currentUser?.userMetadata ?? {};
      avatarUrl = metadata['avatar_url'] ?? metadata['picture'] ?? avatarUrl;
      final p = await repo.client!
          .from('rm_profiles')
          .select()
          .eq('id', repo.owner)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      if (p != null) {
        name = p['name'] ?? '';
        avatarUrl =
            p['avatar_url'] ??
            metadata['avatar_url'] ??
            metadata['picture'] ??
            avatarUrl;
        districtId = p['district_id'] ?? '';
        marketId = p['market_id'] ?? '';
        language = p['language'] ?? language;
        onboarded = marketId.isNotEmpty;
      } else {
        name = metadata['full_name'] ?? metadata['name'] ?? name;
      }
    } catch (_) {
      /* Keep this account's preferences offline. */
    }
  }

  Future<void> setLanguage(String value) async {
    language = value;
    await prefs.setString('language', value);
    notifyListeners();
  }

  Future<void> saveProfile({
    required String newName,
    required String district,
    required String market,
    String? newAvatarUrl,
  }) async {
    final nextAvatarUrl = newAvatarUrl ?? avatarUrl;
    if (signedIn) {
      await repo.client!
          .from('rm_profiles')
          .upsert({
            'id': repo.owner,
            'name': newName,
            'avatar_url': nextAvatarUrl,
            'district_id': district,
            'market_id': market,
            'language': language,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .timeout(const Duration(seconds: 15));
    }
    name = newName;
    avatarUrl = nextAvatarUrl;
    districtId = district;
    marketId = market;
    onboarded = true;
    await prefs.setString('${repo.owner}:name', name);
    await prefs.setString('${repo.owner}:avatar_url', avatarUrl);
    await prefs.setString('${repo.owner}:district', district);
    await prefs.setString('${repo.owner}:market', market);
    notifyListeners();
    unawaited(refresh(market));
  }

  Future<String> uploadProfilePhoto(Uint8List bytes, String contentType) async {
    if (!signedIn) {
      return 'data:$contentType;base64,${base64Encode(bytes)}';
    }
    final path = '${repo.owner}/avatar';
    await repo.client!.storage
        .from('profile-photos')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return '${repo.client!.storage.from('profile-photos').getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> loadPrices({bool force = false}) async {
    var reported = <Price>[];
    try {
      final result = await repo.prices(force: force);
      reported = (result.data as List)
          .map((j) => Price(Map<String, dynamic>.from(j)))
          .toList();
      offline = result.offline;
      checkedAt = result.savedAt;
      message = offline
          ? 'Offline. Showing saved reports and sample prices.'
          : '';
    } catch (_) {
      offline = true;
      message = 'Source prices unavailable. Showing simulated sample prices.';
    }
    prices = DemoPriceProvider.merge(markets, demoCropNames, reported);
    notifyListeners();
  }

  Future<void> refresh([String? market]) async {
    if (busy) return;
    busy = true;
    notifyListeners();
    var result = '';
    try {
      result = await repo.refreshMarket(market ?? marketId);
      await loadPrices(force: true);
    } catch (_) {
      result = 'Could not refresh the source. Showing saved reports.';
    }
    message = result;
    busy = false;
    notifyListeners();
  }

  Future<void> loadPersonal() async {
    final account = repo.owner;
    final loadedCrops = (await repo.loadRecords(
      'crops',
    )).map(FarmCrop.new).toList();
    if (repo.owner != account) return;
    final loadedAlerts = await repo.loadRecords('alerts');
    if (repo.owner != account) return;
    crops = loadedCrops;
    alerts = loadedAlerts;
    notifyListeners();
  }

  Future<void> saveCrop(Json crop) async {
    await repo.saveRecord('crops', crop);
    await loadPersonal();
  }

  Future<void> deleteCrop(String id) async {
    await repo.deleteRecord('crops', id);
    await loadPersonal();
  }

  Future<void> saveAlert(Json alert) async {
    await repo.saveRecord('alerts', alert);
    await loadPersonal();
  }

  Future<void> deleteAlert(String id) async {
    await repo.deleteRecord('alerts', id);
    await loadPersonal();
  }

  Future<void> signIn() async {
    if (repo.client == null) {
      throw StateError('The app connection is not configured.');
    }
    await repo.checkGoogleSignIn();
    await repo.client!.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'in.raithamitra.app://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = repo.client;
    if (client == null) {
      throw StateError('The app connection is not configured.');
    }
    return client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final client = repo.client;
    if (client == null) {
      throw StateError('The app connection is not configured.');
    }
    return client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: 'in.raithamitra.app://login-callback',
    );
  }

  Future<void> sendPasswordReset(String email) async {
    final client = repo.client;
    if (client == null) {
      throw StateError('The app connection is not configured.');
    }
    await client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'in.raithamitra.app://login-callback',
    );
  }

  Future<void> updatePassword(String password) async {
    final client = repo.client;
    if (client == null) {
      throw StateError('The app connection is not configured.');
    }
    await client.auth.updateUser(UserAttributes(password: password));
    passwordRecovery = false;
    entered = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    await repo.client?.auth.signOut(scope: SignOutScope.local);
    entered = false;
    onboarded = false;
    name = '';
    avatarUrl = '';
    crops = [];
    alerts = [];
    marketId = '';
    districtId = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _auth?.cancel();
    super.dispose();
  }
}
