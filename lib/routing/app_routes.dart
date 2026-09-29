/// Chemins de navigation, centralisés pour éviter les chaînes en dur.
abstract final class AppRoutes {
  static const String home = '/home';
  static const String wealth = '/wealth';
  static const String activity = '/activity';
  static const String investments = '/investments';
  static const String profile = '/profile';

  static const String signIn = '/sign-in';
  static const String lock = '/lock';
  static const String loading = '/loading';
  static const String pinSetup = '/security/pin';
  static const String changePin = '/security/pin?change=1';

  static const String newAsset = '/assets/new';
  static const String newLiability = '/liabilities/new';

  static String editAsset(String id) => '/assets/$id';
  static String editLiability(String id) => '/liabilities/$id';
}
