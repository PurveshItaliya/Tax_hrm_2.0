import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheData {
  final dynamic data;
  final int timestamp;

  CacheData({required this.data, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'data': data,
        'timestamp': timestamp,
      };

  factory CacheData.fromJson(Map<String, dynamic> json) {
    return CacheData(
      data: json['data'],
      timestamp: json['timestamp'],
    );
  }
}

class LocalCacheService {
  static final LocalCacheService instance = LocalCacheService._internal();
  LocalCacheService._internal();

  /// Keys
  static const String keyDashboard = 'dashboard_cache';
  static const String keyUserProfile = 'user_profile_cache';
  static const String keyMasterData = 'master_data_cache';
  static const String keyLeaderboard = 'leaderboard_cache';

  /// Saves data to SharedPreferences with current timestamp
  Future<void> saveCache(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = CacheData(
      data: data,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await prefs.setString(key, jsonEncode(cacheData.toJson()));
  }

  /// Retrieves data from cache. 
  /// Returns null if not found or if it exceeds [ttlMilliseconds].
  Future<dynamic> getCache(String key, {int? ttlMilliseconds}) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    
    if (jsonString == null) return null;

    try {
      final cacheData = CacheData.fromJson(jsonDecode(jsonString));
      
      if (ttlMilliseconds != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final age = now - cacheData.timestamp;
        if (age > ttlMilliseconds) {
          // Cache expired
          return null;
        }
      }
      return cacheData.data;
    } catch (e) {
      return null;
    }
  }

  /// Clears specific cache key
  Future<void> clearCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Clears all cache
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
