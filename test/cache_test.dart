import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:raitha_mitra/data/repository.dart';

void main() {
  test('fresh memory entry avoids another fetch', () async {
    final repo = Repository(null);
    var calls = 0;
    Future<int> fetch() async => ++calls;
    final first = await repo.cached('prices', const Duration(hours: 1), fetch);
    final second = await repo.cached('prices', const Duration(hours: 1), fetch);
    expect(calls, 1);
    expect(first.data, second.data);
  });
  test('failed refresh retains data and its original timestamp', () async {
    final repo = Repository(null);
    final first = await repo.cached('prices', Duration.zero, () async => [100]);
    final fallback = await repo.cached(
      'prices',
      Duration.zero,
      () async => throw Exception('offline'),
      force: true,
    );
    expect(fallback.offline, isTrue);
    expect(fallback.savedAt, first.savedAt);
    expect(fallback.data, [100]);
  });
  test('concurrent requests share one fetch', () async {
    final repo = Repository(null);
    final gate = Completer<int>();
    var calls = 0;
    Future<int> fetch() {
      calls++;
      return gate.future;
    }

    final a = repo.cached('prices', Duration.zero, fetch);
    final b = repo.cached('prices', Duration.zero, fetch);
    gate.complete(200);
    final values = await Future.wait([a, b]);
    expect(calls, 1);
    expect(values.map((s) => s.data), [200, 200]);
  });
}
