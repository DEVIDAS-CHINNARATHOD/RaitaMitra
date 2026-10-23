abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zzgpdjqmzepjevnnwvmr.supabase.co',
  );
  // Publishable keys are designed for public client apps; never put a secret key here.
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: "sb_publishable_TWeIJpnnkP5iYHbwJdYJeQ_Bm0kYJax",
  );
}
