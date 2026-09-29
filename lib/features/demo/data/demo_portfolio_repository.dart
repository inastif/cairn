import 'package:cairn/features/demo/data/demo_profiles.dart';
import 'package:cairn/features/portfolio/domain/portfolio_data.dart';
import 'package:cairn/features/portfolio/domain/portfolio_repository.dart';

final class DemoPortfolioRepository implements PortfolioRepository {
  const DemoPortfolioRepository(this.profileId);

  final DemoProfileId profileId;

  @override
  Future<PortfolioData> load({required DateTime asOf}) async =>
      DemoProfiles.build(profileId, asOf: asOf);
}
