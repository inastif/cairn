import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Client Supabase, `null` en mode démonstration. Remplacé dans `main`
/// quand l'application est configurée.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);

/// Vrai tant qu'aucun backend n'est branché.
final isDemoModeProvider = Provider<bool>((ref) => ref.watch(supabaseClientProvider) == null);
