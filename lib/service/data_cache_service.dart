import 'package:flutter/foundation.dart';

class DataCacheService {
  static final DataCacheService _instance = DataCacheService._internal();
  factory DataCacheService() => _instance;
  DataCacheService._internal();

  final Map<String, _CacheEntry> _cache = {};
  
  // Default TTL: 30 minutes
  static const Duration defaultTTL = Duration(minutes: 30);

  /// Get data from cache or return null if expired/not found
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      debugPrint('Cache Expired: $key');
      return null;
    }

    return entry.value as T;
  }

  /// Store data in cache
  void set(String key, dynamic value, {Duration? ttl}) {
    _cache[key] = _CacheEntry(
      value: value,
      expiry: DateTime.now().add(ttl ?? defaultTTL),
    );
    debugPrint('Cache Set: $key');
  }

  /// Get data from cache or fetch it using the provider
  Future<T> getOrFetch<T>(String key, Future<T> Function() fetcher, {Duration? ttl}) async {
    final cachedValue = get<T>(key);
    if (cachedValue != null) {
      debugPrint('Cache Hit: $key');
      return cachedValue;
    }

    debugPrint('Cache Miss: $key');
    final value = await fetcher();
    set(key, value, ttl: ttl);
    return value;
  }

  /// Clear a specific key
  void invalidate(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiry;

  _CacheEntry({required this.value, required this.expiry});
}
