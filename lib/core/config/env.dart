import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised access to environment variables.
/// Always read through this class — never access dotenv directly in features.
class Env {
  Env._();

  // ── OpenRouter ─────────────────────────────────────────────────────────────
  static String get openRouterApiKey =>
      dotenv.env['OPENROUTER_API_KEY'] ?? '';

  static String get openRouterBaseUrl =>
      dotenv.env['OPENROUTER_BASE_URL'] ??
      'https://openrouter.ai/api/v1';

  /// Returns true only when a non-empty API key is configured.
  static bool get hasOpenRouterKey => openRouterApiKey.isNotEmpty;

  // ── Firebase (existing) ────────────────────────────────────────────────────
  static String get firebaseApiKeyWeb =>
      dotenv.env['FIREBASE_API_KEY_WEB'] ?? '';

  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
}
