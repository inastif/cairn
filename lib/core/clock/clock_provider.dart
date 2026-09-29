import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Horloge injectable : les tests la remplacent par une date fixe.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
