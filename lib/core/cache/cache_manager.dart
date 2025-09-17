import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';

class CacheManager {
  static CacheManager? _instance;
  late SharedPreferences _prefs;
  final Map<String, CacheEntry> _memoryCache = {};
  Timer? _cleanupTimer;
  
  CacheManager._();
  
  static Future<CacheManager> get instance async {
    if (_instance == null) {
      _instance = CacheManager._();
      await _instance!._init();
    }
    return _instance!;
  }
  
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _startCleanupTimer();
  }
  
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanupExpiredEntries(),
    );
  }
  
  void _cleanupExpiredEntries() {
    final now = DateTime.now();
    
    // Clean memory cache
    _memoryCache.removeWhere((key, entry) => entry.isExpired(now));
    
    // Clean persistent cache
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('cache_')) {
        final data = _prefs.getString(key);
        if (data != null) {
          try {
            final entry = CacheEntry.fromJson(jsonDecode(data));
            if (entry.isExpired(now)) {
              _prefs.remove(key);
            }
          } catch (_) {
            // Invalid cache entry, remove it
            _prefs.remove(key);
          }
        }
      }
    }
  }
  
  // Get cached data with automatic type casting
  Future<T?> get<T>(
    String key, {
    bool memoryOnly = false,
  }) async {
    // Check memory cache first
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null && !memoryEntry.isExpired(DateTime.now())) {
      return memoryEntry.data as T?;
    }
    
    if (memoryOnly) return null;
    
    // Check persistent cache
    final cacheKey = 'cache_$key';
    final jsonString = _prefs.getString(cacheKey);
    
    if (jsonString != null) {
      try {
        final entry = CacheEntry.fromJson(jsonDecode(jsonString));
        if (!entry.isExpired(DateTime.now())) {
          // Store in memory cache for faster access
          _memoryCache[key] = entry;
          return entry.data as T?;
        }
      } catch (e) {
        // Cache corrupted, remove it
        await _prefs.remove(cacheKey);
      }
    }
    
    return null;
  }
  
  // Set cached data
  Future<void> set<T>(
    String key,
    T data, {
    Duration? expiration,
    bool persistToDisk = true,
  }) async {
    final entry = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      expiration: expiration ?? AppConfig.cacheExpiration,
    );
    
    // Always store in memory
    _memoryCache[key] = entry;
    
    // Optionally persist to disk
    if (persistToDisk) {
      final cacheKey = 'cache_$key';
      await _prefs.setString(cacheKey, jsonEncode(entry.toJson()));
    }
  }
  
  // Remove specific cache entry
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _prefs.remove('cache_$key');
  }
  
  // Clear all cache
  Future<void> clearAll() async {
    _memoryCache.clear();
    
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('cache_')) {
        await _prefs.remove(key);
      }
    }
  }
  
  // Get cache size
  Future<CacheStats> getStats() async {
    int memoryEntries = _memoryCache.length;
    int diskEntries = 0;
    int totalSizeBytes = 0;
    
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('cache_')) {
        diskEntries++;
        final value = _prefs.getString(key);
        if (value != null) {
          totalSizeBytes += value.length * 2; // Approximate UTF-16 size
        }
      }
    }
    
    return CacheStats(
      memoryEntries: memoryEntries,
      diskEntries: diskEntries,
      totalSizeBytes: totalSizeBytes,
    );
  }
  
  void dispose() {
    _cleanupTimer?.cancel();
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration expiration;
  
  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiration,
  });
  
  bool isExpired(DateTime now) {
    return now.difference(timestamp) > expiration;
  }
  
  Map<String, dynamic> toJson() => {
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'expirationMs': expiration.inMilliseconds,
  };
  
  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      expiration: Duration(milliseconds: json['expirationMs']),
    );
  }
}

class CacheStats {
  final int memoryEntries;
  final int diskEntries;
  final int totalSizeBytes;
  
  CacheStats({
    required this.memoryEntries,
    required this.diskEntries,
    required this.totalSizeBytes,
  });
  
  String get formattedSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) return '${(totalSizeBytes / 1024).toStringAsFixed(2)} KB';
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

// Cache keys constants
class CacheKeys {
  static const String userProfile = 'user_profile';
  static const String activeGames = 'active_games';
  static const String taskLibrary = 'task_library';
  static const String communityTasks = 'community_tasks';
  static const String gameHistory = 'game_history';
  
  static String game(String gameId) => 'game_$gameId';
  static String userGames(String userId) => 'user_games_$userId';
  static String taskSubmissions(String taskId) => 'submissions_$taskId';
}

// Network-aware cache service
class NetworkAwareCacheService {
  final CacheManager _cacheManager;
  final bool Function() _isOnline;
  
  NetworkAwareCacheService({
    required CacheManager cacheManager,
    required bool Function() isOnline,
  }) : _cacheManager = cacheManager,
       _isOnline = isOnline;
  
  Future<T?> fetchWithCache<T>({
    required String cacheKey,
    required Future<T> Function() networkFetch,
    Duration? cacheExpiration,
    bool forceRefresh = false,
  }) async {
    // If offline, always use cache
    if (!_isOnline()) {
      return _cacheManager.get<T>(cacheKey);
    }
    
    // If not forcing refresh, try cache first
    if (!forceRefresh) {
      final cached = await _cacheManager.get<T>(cacheKey);
      if (cached != null) return cached;
    }
    
    // Fetch from network
    try {
      final data = await networkFetch();
      
      // Cache the result
      await _cacheManager.set(
        cacheKey,
        data,
        expiration: cacheExpiration,
      );
      
      return data;
    } catch (e) {
      // On network error, fall back to cache
      final cached = await _cacheManager.get<T>(cacheKey);
      if (cached != null) return cached;
      
      // Re-throw if no cached data available
      rethrow;
    }
  }
}