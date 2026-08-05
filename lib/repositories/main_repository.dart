import 'package:tax_hrm/services/local_cache_service.dart';
import 'package:tax_hrm/api/companiapi.dart';
import 'package:tax_hrm/api/attendanceapi.dart';
import 'package:tax_hrm/utils/attendance_perf_logger.dart';

class MainRepository {
  final LocalCacheService _cacheService = LocalCacheService.instance;
  final AttendancePerformanceLogger _logger = AttendancePerformanceLogger.instance;

  /// Fetch initial dashboard data (Parallel execution with caching)
  Future<Map<String, dynamic>> fetchDashboardData() async {
    Map<String, dynamic> result = {};

    // 1. Memory / Local Cache first (Instant load)
    var cachedCompanies = await _cacheService.getCache(LocalCacheService.keyMasterData, ttlMilliseconds: 24 * 60 * 60 * 1000); // 24 hours TTL
    if (cachedCompanies != null) {
      result['companies'] = cachedCompanies;
    }

    // 2. Background Refresh (SWR - Stale While Revalidate)
    _refreshDashboardDataInBackground();

    return result;
  }

  void _refreshDashboardDataInBackground() async {
    try {
      final now = DateTime.now();
      final monthStr = now.month.toString().padLeft(2, '0');
      final yearStr = now.year.toString();

      // Parallel execution of independent APIs
      final futures = await _logger.track('fetchDashboardAPIs', executionMode: 'parallel', () => Future.wait([
        CompanyDataApis().getCompanyDataList(),
        AttendanceApis().getCompanyDataList(monthStr, yearStr),
      ]));

      final companies = futures[0];
      final leaderboard = futures[1];

      // Update Local Cache
      await _cacheService.saveCache(LocalCacheService.keyMasterData, companies);
      await _cacheService.saveCache(LocalCacheService.keyLeaderboard, leaderboard);
      
    } catch (e) {
      // Fallback to cache silently, no UI interruption
      AttendancePerformanceLogger.instance.track('dashboard_bg_refresh_error', () async => throw e);
    }
  }
}
