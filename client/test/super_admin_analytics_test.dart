import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/super_admin/models/global_analytics_model.dart';
import 'package:enx_money/features/super_admin/data/super_admin_repository.dart';

void main() {
  group('Super Admin & Global Analytics Architecture Tests', () {
    test('GlobalKpiSummary computes correct ratios and percentages', () {
      const kpis = GlobalKpiSummary(
        totalWorldwideUsers: 100000,
        userGrowthPercentage: 15.0,
        dailyActiveUsers: 25000,
        monthlyActiveUsers: 80000,
        businessAccountsCount: 35000,
        personalAccountsCount: 65000,
        activeLiveSessions: 1200,
      );

      expect(kpis.totalWorldwideUsers, 100000);
      expect(kpis.businessRatio, 35.0);
      expect(kpis.personalRatio, 65.0);
      expect(kpis.dauMauRatio, 31.25);
      expect(kpis.userGrowthPercentage, 15.0);
    });

    test('SuperAdminRepository loads geo metrics and retention data horizons', () async {
      final repo = SuperAdminRepository();
      await repo.loadDashboardData();

      expect(repo.isLoaded, true);
      expect(repo.kpis.totalWorldwideUsers, greaterThan(0));

      // Geo Metrics
      expect(repo.geoMetrics.isNotEmpty, true);
      final india = repo.geoMetrics.firstWhere((g) => g.countryCode == 'IN');
      expect(india.countryName, 'India');
      expect(india.states.isNotEmpty, true);

      // Retention Horizons
      final ret7 = repo.getRetention(7);
      final ret30 = repo.getRetention(30);
      final ret90 = repo.getRetention(90);

      expect(ret7.length, 7);
      expect(ret30.length, 30);
      expect(ret90.length, 90);
    });

    test('User telemetry search, filtering and pagination work accurately', () async {
      final repo = SuperAdminRepository();
      await repo.loadDashboardData();

      // Search by name
      final searchResult = repo.getFilteredUsers(query: 'Revanth');
      expect(searchResult.any((u) => u.name.contains('Revanth')), true);

      // Filter by Account Type
      final businessUsers = repo.getFilteredUsers(accountFilter: 'Business', pageSize: 100);
      expect(businessUsers.every((u) => u.accountType == 'Business'), true);

      final personalUsers = repo.getFilteredUsers(accountFilter: 'Personal', pageSize: 100);
      expect(personalUsers.every((u) => u.accountType == 'Personal'), true);

      // Filter by Status
      final suspendedUsers = repo.getFilteredUsers(statusFilter: 'Suspended', pageSize: 100);
      expect(suspendedUsers.every((u) => u.status == 'Suspended'), true);
    });

    test('Toggling user status switches between Active and Suspended', () async {
      final repo = SuperAdminRepository();
      await repo.loadDashboardData();

      final firstUser = repo.allUsers.first;
      final initialStatus = firstUser.status;

      await repo.toggleUserStatus(firstUser.id);
      final updatedUser = repo.allUsers.firstWhere((u) => u.id == firstUser.id);
      expect(updatedUser.status, initialStatus == 'Active' ? 'Suspended' : 'Active');

      // Toggle back
      await repo.toggleUserStatus(firstUser.id);
      final restoredUser = repo.allUsers.firstWhere((u) => u.id == firstUser.id);
      expect(restoredUser.status, initialStatus);
    });

    test('CSV export generates proper headers and comma-separated user logs', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final repo = SuperAdminRepository();
      await repo.loadDashboardData();

      final csv = await repo.exportCsvReport();
      expect(csv.contains('GLOBAL USER TELEMETRY AUDIT REPORT'), true);
      expect(csv.contains('User ID,Full Name,Email Address,Account Type'), true);
      expect(csv.contains('ENX-8291'), true);
      expect(csv.contains('Polamreddy Revanth'), true);
    });
  });
}
