import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../models/anime.dart';
import '../services/anime_api_service.dart';
import '../services/local_database_service.dart';

enum WatchlistActionResult { added, removed, needsLogin }

class AppState extends ChangeNotifier {
  final AnimeApiService api;
  final LocalDatabaseService db;
  AppState(this.api, this.db);

  bool isDark = true;
  bool loading = false;
  String? error;
  int heroIndex = 0;
  Timer? _heroTimer;
  List<Anime> top = [];
  List<Anime> seasonal = [];
  List<Anime> searchResults = [];
  List<Anime> recommendations = [];
  List<Anime> viewAllItems = [];
  final Set<int> watchlistIds = {};
  final List<String> behaviorKeywords = [];
  AppUser? currentUser;
  bool authBusy = false;
  String? authError;
  String? lastSearchQuery;
  int lastSearchCount = 0;
  DateTime? lastSearchTime;
  String selectedSeason = 'spring';
  int selectedYear = DateTime.now().year;
  List<Anime> seasonalCatalog = [];
  List<AppUser> adminUsers = [];
  List<Map<String, Object?>> adminUsersRaw = [];
  List<Map<String, Object?>> customAnimeRaw = [];
  List<Map<String, Object?>> topSearchKeywords = [];
  Map<String, int> adminOverview = {'users': 0, 'searches': 0, 'watchlistItems': 0};

  final List<String> smartKeywords = const [
    'Overpowered MC', 'Isekai', 'Reincarnation', 'Time Travel', 'School Life',
    'Shounen', 'Sad', 'Romance', 'Magic', 'Supernatural', 'Revenge', 'Comedy',
    'Dark Fantasy', 'Sports', 'Slice of Life', 'Psychological'
  ];

  Future<void> init() async {
    await _loadPrefs();
    currentUser = await db.getActiveUser();
    await _loadBehaviorForCurrentUser();
    await _syncUserWatchlist();
    await refresh();
    await loadSeasonalCatalog();
    await loadAdminOverview();
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      top = await api.topAnime(limit: 10);
      seasonal = await api.seasonalAnime(limit: 12);
      final custom = await _customAnimeAsList();
      if (custom.isNotEmpty) {
        top = [...custom.take(4), ...top].toList();
        seasonal = [...custom.take(4), ...seasonal].toList();
      }
      viewAllItems = top;
      await makeRecommendations();
      _startHeroTimer();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    _rememberKeyword(clean);
    loading = true;
    lastSearchQuery = clean;
    notifyListeners();
    try {
      searchResults = await api.searchAnime(clean);
      lastSearchCount = searchResults.length;
      lastSearchTime = DateTime.now();
      await db.logSearch(userId: currentUser?.id, query: clean);
      await makeRecommendations();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> makeRecommendations() async {
    final learned = userBehaviorGenres();
    final seed = learned.isNotEmpty
        ? learned.take(2).join(' ')
        : (behaviorKeywords.isNotEmpty ? behaviorKeywords.last : 'action adventure');
    try {
      recommendations = await api.recommendationByKeyword(seed);
    } catch (_) {
      recommendations = seasonal.take(8).toList();
    }
  }

  void _startHeroTimer() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (top.isEmpty) return;
      heroIndex = (heroIndex + 1) % top.length.clamp(1, 9999);
      notifyListeners();
    });
  }

  void setHeroIndex(int index) {
    if (top.isEmpty) return;
    heroIndex = index % top.length;
    notifyListeners();
  }

  void toggleTheme() {
    isDark = !isDark;
    _savePrefs();
    notifyListeners();
  }

  bool isInWatchlist(int id) => watchlistIds.contains(id);

  Future<WatchlistActionResult> toggleWatchlist(Anime anime) async {
    if (currentUser == null) return WatchlistActionResult.needsLogin;
    final existed = watchlistIds.contains(anime.id);
    await db.toggleWatchlist(userId: currentUser!.id, animeId: anime.id);
    if (watchlistIds.contains(anime.id)) {
      watchlistIds.remove(anime.id);
    } else {
      watchlistIds.add(anime.id);
      _rememberKeyword([...anime.genres, ...anime.themes].take(2).join(' '));
    }
    await _savePrefs();
    await makeRecommendations();
    notifyListeners();
    return existed ? WatchlistActionResult.removed : WatchlistActionResult.added;
  }

  Future<void> _syncUserWatchlist() async {
    watchlistIds.clear();
    if (currentUser == null) return;
    final ids = await db.getUserWatchlistIds(currentUser!.id);
    watchlistIds.addAll(ids);
  }

  void _rememberKeyword(String keyword) {
    if (currentUser == null) return;
    final clean = keyword.trim();
    if (clean.isEmpty) return;
    behaviorKeywords.remove(clean);
    behaviorKeywords.add(clean);
    if (behaviorKeywords.length > 8) behaviorKeywords.removeAt(0);
    _savePrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    isDark = prefs.getBool('isDark') ?? true;
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark);
    await prefs.setStringList(_behaviorPrefsKey(), behaviorKeywords);
  }

  String _behaviorPrefsKey() => 'behaviorKeywords_${currentUser?.id ?? 'guest'}';

  Future<void> _loadBehaviorForCurrentUser() async {
    behaviorKeywords.clear();
    final prefs = await SharedPreferences.getInstance();
    behaviorKeywords.addAll(prefs.getStringList(_behaviorPrefsKey()) ?? []);
  }

  Future<bool> signup({required String email, required String password}) async {
    authBusy = true;
    authError = null;
    notifyListeners();
    try {
      currentUser = await db.registerUser(
        username: email.split('@').first,
        email: email,
        password: password,
      );
      await _syncUserWatchlist();
      await _loadBehaviorForCurrentUser();
      await loadAdminOverview();
      return true;
    } catch (_) {
      authError = 'Account already exists or invalid information.';
      return false;
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    authBusy = true;
    authError = null;
    notifyListeners();
    try {
      final user = await db.login(email: email, password: password);
      if (user == null) {
        authError = 'Invalid credentials or your account is blocked.';
        return false;
      }
      currentUser = user;
      await _syncUserWatchlist();
      await _loadBehaviorForCurrentUser();
      await loadAdminOverview();
      return true;
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  Future<bool> forgotPassword(String email, String newPassword) async {
    authBusy = true;
    authError = null;
    notifyListeners();
    try {
      await db.updatePasswordByEmail(email: email, newPassword: newPassword);
      return true;
    } catch (_) {
      authError = 'Unable to reset password.';
      return false;
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await db.logout();
    currentUser = null;
    watchlistIds.clear();
    behaviorKeywords.clear();
    notifyListeners();
  }

  Future<bool> updateMyProfile({
    required String username,
    required String email,
    String? password,
    String? profileImagePath,
  }) async {
    if (currentUser == null) return false;
    try {
      await db.updateUserProfile(
        userId: currentUser!.id,
        username: username,
        email: email,
        password: password,
        profileImagePath: profileImagePath ?? currentUser!.profileImagePath,
      );
      currentUser = await db.getActiveUser();
      await loadAdminOverview();
      notifyListeners();
      return true;
    } catch (_) {
      authError = 'Failed to update profile.';
      notifyListeners();
      return false;
    }
  }

  Future<void> setViewAllItems(List<Anime> items) async {
    viewAllItems = items;
    notifyListeners();
  }

  Future<void> loadSeasonalCatalog() async {
    loading = true;
    notifyListeners();
    try {
      seasonalCatalog = await api.seasonalBy(selectedSeason, selectedYear, limit: 24);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> updateSeasonSelection({required String season, required int year}) async {
    selectedSeason = season;
    selectedYear = year;
    await loadSeasonalCatalog();
  }

  Future<void> loadAdminOverview() async {
    adminOverview = await db.adminStats();
    adminUsers = await db.latestUsers(limit: 10);
    adminUsersRaw = await db.adminUsersWithHashes(limit: 100);
    customAnimeRaw = await db.listCustomAnime();
    topSearchKeywords = await db.topSearches();
    notifyListeners();
  }

  Future<void> adminBlockUser(int userId, bool blocked) async {
    await db.blockUser(userId, blocked);
    if (currentUser?.id == userId && blocked) {
      currentUser = null;
      watchlistIds.clear();
    }
    await loadAdminOverview();
  }

  Future<void> adminDeleteUser(int userId) async {
    await db.deleteUser(userId);
    if (currentUser?.id == userId) {
      currentUser = null;
      watchlistIds.clear();
    }
    await loadAdminOverview();
  }

  Future<void> adminAddUser({
    required String username,
    required String email,
    required String password,
  }) async {
    await db.adminCreateUser(username: username, email: email, password: password);
    await loadAdminOverview();
  }

  Future<void> adminAddAnime({
    required String title,
    required String imageUrl,
    required String synopsis,
    required String genres,
  }) async {
    await db.addCustomAnime(
      title: title,
      imageUrl: imageUrl,
      synopsis: synopsis,
      genres: genres,
    );
    await loadAdminOverview();
    await refresh();
  }

  Future<void> adminRemoveAnime(int id) async {
    await db.removeCustomAnime(id);
    await loadAdminOverview();
    await refresh();
  }

  List<String> userBehaviorGenres() {
    final bucket = <String, int>{};
    for (final keyword in behaviorKeywords) {
      final parts = keyword.split(' ');
      for (final p in parts) {
        final clean = p.trim().toLowerCase();
        if (clean.length < 3) continue;
        bucket[clean] = (bucket[clean] ?? 0) + 1;
      }
    }
    final sorted = bucket.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).map((e) => e.key).toList();
  }

  Future<List<Anime>> _customAnimeAsList() async {
    final rows = await db.listCustomAnime();
    return rows.map((e) {
      final genres = (e['genres']?.toString() ?? 'Anime')
          .split(',')
          .map((g) => g.trim())
          .where((g) => g.isNotEmpty)
          .toList();
      return Anime(
        id: -(e['id'] as int),
        title: e['title'].toString(),
        imageUrl: e['image_url'].toString(),
        largeImageUrl: e['image_url'].toString(),
        synopsis: e['synopsis'].toString(),
        score: 8.0,
        rank: null,
        year: DateTime.now().year,
        rating: 'PG-13',
        trailerUrl: null,
        malUrl: 'https://myanimelist.net',
        genres: genres,
        themes: const [],
      );
    }).toList();
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    super.dispose();
  }
}
