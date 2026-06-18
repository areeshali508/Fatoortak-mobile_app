import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Simple in-memory cache service for frequently accessed data
/// 
/// This provides fast access to cached data without disk I/O
/// For persistent caching, use Hive or shared_preferences
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, _CacheEntry> _cache = {};
  
  /// Default cache duration (5 minutes)
  static const Duration defaultDuration = Duration(minutes: 5);

  /// Store data in cache with optional expiration
  void put<T>(
    String key,
    T data, {
    Duration? duration,
  }) {
    _cache[key] = _CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(duration ?? defaultDuration),
    );
    
    if (kDebugMode) {
      debugPrint('📦 Cache PUT: $key (expires in ${duration ?? defaultDuration})');
    }
  }

  /// Get data from cache if not expired
  T? get<T>(String key) {
    final _CacheEntry? entry = _cache[key];
    
    if (entry == null) {
      if (kDebugMode) {
        debugPrint('📦 Cache MISS: $key');
      }
      return null;
    }

    // Check if expired
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      if (kDebugMode) {
        debugPrint('📦 Cache EXPIRED: $key');
      }
      return null;
    }

    if (kDebugMode) {
      debugPrint('📦 Cache HIT: $key');
    }
    return entry.data as T?;
  }

  /// Check if key exists and is not expired
  bool has(String key) {
    final _CacheEntry? entry = _cache[key];
    if (entry == null) return false;
    
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return false;
    }
    
    return true;
  }

  /// Remove specific key from cache
  void remove(String key) {
    _cache.remove(key);
    if (kDebugMode) {
      debugPrint('📦 Cache REMOVE: $key');
    }
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    if (kDebugMode) {
      debugPrint('📦 Cache CLEARED');
    }
  }

  /// Clear expired entries
  void clearExpired() {
    final DateTime now = DateTime.now();
    _cache.removeWhere((String key, _CacheEntry entry) {
      return now.isAfter(entry.expiresAt);
    });
    if (kDebugMode) {
      debugPrint('📦 Cache CLEARED EXPIRED');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final DateTime now = DateTime.now();
    int expired = 0;
    int valid = 0;

    for (final _CacheEntry entry in _cache.values) {
      if (now.isAfter(entry.expiresAt)) {
        expired++;
      } else {
        valid++;
      }
    }

    return {
      'total': _cache.length,
      'valid': valid,
      'expired': expired,
    };
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry({
    required this.data,
    required this.expiresAt,
  });
}

/// Cache keys for commonly cached data
class CacheKeys {
  static const String dashboardStats = 'dashboard_stats';
  static const String revenueMetrics = 'revenue_metrics';
  static const String invoiceList = 'invoice_list';
  static const String customerList = 'customer_list';
  static const String productList = 'product_list';
  static const String companyList = 'company_list';
  static const String userProfile = 'user_profile';
  
  /// Generate cache key with parameters
  static String withParams(String base, Map<String, String> params) {
    final String paramsStr = params.entries
        .map((MapEntry<String, String> e) => '${e.key}=${e.value}')
        .join('&');
    return '${base}_$paramsStr';
  }
}

/// Extension for easy caching of API responses
extension CacheableResponse on Map<String, dynamic> {
  /// Convert to JSON string for caching
  String toJsonString() => jsonEncode(this);
  
  /// Parse from JSON string
  static Map<String, dynamic> fromJsonString(String json) {
    return jsonDecode(json) as Map<String, dynamic>;
  }
}
