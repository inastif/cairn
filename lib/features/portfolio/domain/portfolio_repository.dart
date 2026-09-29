import 'package:cairn/features/portfolio/domain/portfolio_data.dart';

/// Source des données financières. L'UI ne connaît que cette interface :
/// l'implémentation de démo sera remplacée par l'implémentation Supabase
/// (module 2) sans toucher aux écrans.
abstract interface class PortfolioRepository {
  Future<PortfolioData> load({required DateTime asOf});
}
