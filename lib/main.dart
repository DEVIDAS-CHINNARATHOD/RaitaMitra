import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'data/repository.dart';
import 'state.dart';
import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = AppConfig.supabaseUrl;
  const key = AppConfig.publishableKey;
  SupabaseClient? client;
  if (key.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: key);
    client = Supabase.instance.client;
  }
  final state = AppState(Repository(client));
  runApp(RaithaMitraApp(state: state));
  await state.initialize();
}
