import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'demo_price_provider.dart';
import '../config.dart';
import 'package:http/http.dart' as http;

class Repository {
  Repository(this.client);
  final SupabaseClient? client;
  Database? _db;
  final Map<String, CachedSnapshot> _memory = {};
  final Map<String, Future<CachedSnapshot>> _inflight = {};
  Future<void> checkGoogleSignIn() async {
    final response = await http
        .get(
          Uri.parse('${AppConfig.supabaseUrl}/auth/v1/settings'),
          headers: {
            'apikey': AppConfig.publishableKey,
            'Cache-Control': 'no-cache',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 ||
        (jsonDecode(response.body) as Json)['external']?['google'] != true) {
      throw StateError('Google sign-in is not available yet.');
    }
  }

  Future<void> open() async {
    _db = await openDatabase(
      p.join(await getDatabasesPath(), 'raitha_mitra.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE cache (key TEXT PRIMARY KEY, body TEXT NOT NULL, saved_at TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE crops (id TEXT PRIMARY KEY, owner TEXT NOT NULL, body TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE alerts (id TEXT PRIMARY KEY, owner TEXT NOT NULL, body TEXT NOT NULL)',
        );
      },
    );
  }

  Future<CachedSnapshot> cached(
    String key,
    Duration ttl,
    Future<dynamic> Function() fetch, {
    bool force = false,
  }) async {
    CachedSnapshot? saved = _memory[key];
    if (saved == null && _db != null) {
      final rows = await _db!.query('cache', where: 'key=?', whereArgs: [key]);
      if (rows.isNotEmpty) {
        try {
          saved = CachedSnapshot(
            jsonDecode(rows.first['body'] as String),
            DateTime.parse(rows.first['saved_at'] as String),
          );
          _memory[key] = saved;
        } catch (_) {
          await _db!.delete('cache', where: 'key=?', whereArgs: [key]);
        }
      }
    }
    if (!force &&
        saved != null &&
        DateTime.now().difference(saved.savedAt) < ttl) {
      return saved;
    }
    if (_inflight.containsKey(key)) return _inflight[key]!;
    final fallback = saved;
    final task = () async {
      try {
        final data = await fetch().timeout(const Duration(seconds: 15));
        final snapshot = CachedSnapshot(data, DateTime.now());
        if (_db != null) {
          await _db!.insert('cache', {
            'key': key,
            'body': jsonEncode(data),
            'saved_at': snapshot.savedAt.toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        _memory[key] = snapshot;
        return snapshot;
      } catch (_) {
        if (fallback != null) {
          return CachedSnapshot(fallback.data, fallback.savedAt, offline: true);
        }
        rethrow;
      }
    }();
    _inflight[key] = task;
    try {
      return await task;
    } finally {
      _inflight.remove(key);
    }
  }

  Future<Json> directory() async {
    try {
      final result = await cached(
        'directory',
        const Duration(days: 7),
        () async {
          if (client == null) throw StateError('No connection');
          return {
            'districts': await client!
                .from('rm_districts')
                .select()
                .order('name'),
            'markets': await client!.from('rm_markets').select().order('name'),
          };
        },
      );
      return Map<String, dynamic>.from(result.data);
    } catch (_) {
      return jsonDecode(
            await rootBundle.loadString('assets/data/directory.json'),
          )
          as Json;
    }
  }

  Future<CachedSnapshot> prices({bool force = false}) =>
      cached('latest_prices', const Duration(days: 3650), () async {
        if (client == null) {
          throw StateError('Market connection is not configured.');
        }
        final result = <dynamic>[];
        for (int offset = 0; offset < 10000; offset += 1000) {
          final page = await client!
              .from('rm_latest_prices')
              .select()
              .order('market_id')
              .order('commodity_id')
              .order('variety')
              .order('grade')
              .range(offset, offset + 999);
          result.addAll(page);
          if (page.length < 1000) break;
        }
        return result;
      }, force: force);
  Future<List<Price>> history(Price price) async {
    if (price.isDemo) return DemoPriceProvider.history(price);
    final result = await cached(
      'history:${price.marketId}:${price.commodityId}:${price.variety}:${price.grade}',
      const Duration(hours: 6),
      () async {
        if (client == null) return <dynamic>[];
        return client!
            .from('rm_prices')
            .select()
            .eq('market_id', price.marketId)
            .eq('commodity_id', price.commodityId)
            .eq('variety', price.variety)
            .eq('grade', price.grade)
            .order('report_date', ascending: false)
            .limit(180);
      },
    );
    return (result.data as List)
        .map(
          (j) => Price({
            ...Map<String, dynamic>.from(j),
            'commodity_name': price.name,
          }),
        )
        .toList()
        .reversed
        .toList();
  }

  Future<Json> priceOutlook(
    Price price, {
    String language = 'en',
    bool force = false,
  }) async {
    if (price.isDemo) {
      throw StateError('LLM forecasts are disabled for synthetic demo prices.');
    }
    final activeClient = client;
    if (activeClient == null) {
      throw StateError('The market connection is not configured.');
    }
    if (activeClient.auth.currentUser == null) {
      throw StateError('Sign in to request an LLM price outlook.');
    }
    final key =
        'llm_outlook_v2:$language:${price.marketId}:${price.commodityId}:${price.variety}:${price.grade}:${dateOnly(price.date)}:${price.modal}';
    final result = await cached(key, const Duration(days: 3650), () async {
      final response = await activeClient.functions.invoke(
        'ask-mitra',
        body: {
          'mode': 'price_outlook',
          'market_id': price.marketId,
          'commodity_id': price.commodityId,
          'variety': price.variety,
          'grade': price.grade,
          'language': language,
        },
      );
      if (response.data is! Map) {
        throw StateError('The LLM did not return a price outlook.');
      }
      return Map<String, dynamic>.from(response.data as Map);
    }, force: force);
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<List<Json>> forecasts(Price price) async {
    if (client == null) return [];
    final result = await cached(
      'forecast:${price.marketId}:${price.commodityId}:${price.variety}:${price.grade}',
      const Duration(hours: 1),
      () => client!
          .from('rm_forecasts')
          .select()
          .eq('market_id', price.marketId)
          .eq('commodity_id', price.commodityId)
          .eq('variety', price.variety)
          .eq('grade', price.grade)
          .gte('target_date', dateOnly(DateTime.now()))
          .gt('valid_until', DateTime.now().toUtc().toIso8601String())
          .order('target_date'),
    );
    return (result.data as List)
        .map((j) => Map<String, dynamic>.from(j))
        .toList();
  }

  Future<String> refreshMarket(String id) async {
    if (client == null) return 'Market connection is not configured.';
    try {
      final response = await client!.functions
          .invoke('refresh-market', body: {'market_id': id})
          .timeout(const Duration(seconds: 40));
      final data = response.data;
      if (data is Map) {
        return data['message']?.toString() ?? 'Market data checked.';
      }
      return 'Market data checked. Saved reports remain available.';
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['message'] is String) {
        return details['message'] as String;
      }
      return 'Could not contact the market service. Saved reports remain available.';
    } catch (_) {
      return 'Could not contact the market service. Saved reports remain available.';
    }
  }

  String get owner => client?.auth.currentUser?.id ?? 'device-preview';
  Future<List<Json>> localRecords(String table, {String? account}) async =>
      (await _db!.query(
        table,
        where: 'owner=?',
        whereArgs: [account ?? owner],
      )).map((r) => jsonDecode(r['body'] as String) as Json).toList();
  Future<List<Json>> loadRecords(String table) async {
    final account = owner;
    if (account == 'device-preview') {
      return localRecords(table, account: account);
    }
    try {
      final rows = await client!
          .from('rm_$table')
          .select()
          .eq('user_id', account)
          .order('created_at')
          .timeout(const Duration(seconds: 12));
      await _db!.transaction((txn) async {
        await txn.delete(table, where: 'owner=?', whereArgs: [account]);
        for (final row in rows) {
          await txn.insert(table, {
            'id': row['id'],
            'owner': account,
            'body': jsonEncode(row),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
      return rows;
    } catch (_) {
      return localRecords(table, account: account);
    }
  }

  Future<void> saveRecord(String table, Json data) async {
    final account = owner;
    final row = {...data};
    if (account != 'device-preview') {
      row['user_id'] = account;
      await client!
          .from('rm_$table')
          .upsert(row)
          .timeout(const Duration(seconds: 15));
    }
    await _db!.insert(table, {
      'id': row['id'],
      'owner': account,
      'body': jsonEncode(row),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteRecord(String table, String id) async {
    final account = owner;
    if (account != 'device-preview') {
      await client!
          .from('rm_$table')
          .delete()
          .eq('id', id)
          .eq('user_id', account)
          .timeout(const Duration(seconds: 15));
    }
    await _db!.delete(
      table,
      where: 'id=? AND owner=?',
      whereArgs: [id, account],
    );
  }

  Future<void> clearMarketCache() async {
    _memory.clear();
    await _db!.delete('cache');
  }
}
